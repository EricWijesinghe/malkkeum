//! Removes embedded metadata (EXIF with GPS, XMP, IPTC, text chunks) from uploaded photos before they are
//! stored. Pixels are never decoded or re-encoded: only the container is rewritten, so quality is untouched.
//! A JPEG keeps a one-tag EXIF block with its orientation, or phone photos would display sideways.
//! HEIC cannot be rewritten without a codec, so the caller refuses it (the apps send re-encoded JPEG).

const JPEG_SOI: [u8; 2] = [0xFF, 0xD8];
const MARKER_SOS: u8 = 0xDA;
const MARKER_EOI: u8 = 0xD9;
const MARKER_APP1: u8 = 0xE1;
const MARKER_APP2: u8 = 0xE2;
const MARKER_APP0: u8 = 0xE0;
const MARKER_APP14: u8 = 0xEE;
const MARKER_COM: u8 = 0xFE;
const ICC_ID: &[u8] = b"ICC_PROFILE\0";
const EXIF_ID: &[u8] = b"Exif\0\0";
const TAG_ORIENTATION: u16 = 0x0112;

const PNG_SIG: [u8; 8] = [0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A];
/// PNG chunks that carry metadata: EXIF, text (XMP lives in iTXt) and the modification time.
const PNG_DROP: [&[u8; 4]; 5] = [b"eXIf", b"tEXt", b"zTXt", b"iTXt", b"tIME"];

const WEBP_FLAG_EXIF_XMP: u8 = 0x0C;

/// The same image without metadata, or None when the container is malformed or not rewritable.
pub fn strip(ext: &str, bytes: &[u8]) -> Option<Vec<u8>> {
    match ext {
        "jpg" => strip_jpeg(bytes),
        "png" => strip_png(bytes),
        "webp" => strip_webp(bytes),
        _ => None,
    }
}

fn be16(b: &[u8]) -> Option<usize> {
    Some(usize::from(u16::from_be_bytes([*b.first()?, *b.get(1)?])))
}

fn strip_jpeg(src: &[u8]) -> Option<Vec<u8>> {
    if !src.starts_with(&JPEG_SOI) {
        return None;
    }
    let mut out = JPEG_SOI.to_vec();
    let mut orientation = None;
    let mut pos = 2;
    loop {
        if *src.get(pos)? != 0xFF {
            return None;
        }
        let marker = *src.get(pos + 1)?;
        if marker == 0xFF {
            pos += 1; // fill byte
            continue;
        }
        if marker == MARKER_EOI {
            return None; // no scan data
        }
        let len = be16(src.get(pos + 2..)?)?;
        let seg = src.get(pos + 2..pos + 2 + len).filter(|_| len >= 2)?;
        let body = &seg[2..];
        let keep = match marker {
            MARKER_APP1 => {
                orientation = orientation.or_else(|| body.strip_prefix(EXIF_ID).and_then(exif_orientation));
                false
            }
            MARKER_APP2 => body.starts_with(ICC_ID),
            MARKER_APP0 | MARKER_APP14 => true,
            0xE3..=0xED | 0xEF | MARKER_COM => false,
            _ => true,
        };
        if keep {
            out.extend_from_slice(&src[pos..pos + 2 + len]);
        }
        pos += 2 + len;
        if marker == MARKER_SOS {
            out.extend_from_slice(&src[pos..]);
            break;
        }
    }
    if let Some(o) = orientation.filter(|o| *o > 1) {
        // Right after SOI is a valid place for APP1; readers accept it before or after JFIF.
        out.splice(2..2, orientation_block(o));
    }
    Some(out)
}

/// The EXIF orientation (1-8) from a TIFF block, if IFD0 has one.
fn exif_orientation(tiff: &[u8]) -> Option<u16> {
    let little = match tiff.get(..2)? {
        b"II" => true,
        b"MM" => false,
        _ => return None,
    };
    let u16at = |o: usize| -> Option<u16> {
        let b = [*tiff.get(o)?, *tiff.get(o + 1)?];
        Some(if little { u16::from_le_bytes(b) } else { u16::from_be_bytes(b) })
    };
    let u32at = |o: usize| -> Option<usize> {
        let b = [*tiff.get(o)?, *tiff.get(o + 1)?, *tiff.get(o + 2)?, *tiff.get(o + 3)?];
        usize::try_from(if little { u32::from_le_bytes(b) } else { u32::from_be_bytes(b) }).ok()
    };
    let ifd = u32at(4)?;
    let count = usize::from(u16at(ifd)?);
    (0..count).find_map(|i| {
        let entry = ifd + 2 + i * 12;
        (u16at(entry)? == TAG_ORIENTATION)
            .then(|| u16at(entry + 8))
            .flatten()
            .filter(|o| (1..=8).contains(o))
    })
}

/// APP1 segment holding only the orientation tag (big-endian TIFF, one IFD entry).
fn orientation_block(orientation: u16) -> Vec<u8> {
    let mut b = vec![0xFF, MARKER_APP1, 0x00, 0x22];
    b.extend_from_slice(EXIF_ID);
    b.extend_from_slice(b"MM\x00\x2A\x00\x00\x00\x08\x00\x01");
    b.extend_from_slice(&TAG_ORIENTATION.to_be_bytes());
    b.extend_from_slice(&[0x00, 0x03, 0x00, 0x00, 0x00, 0x01]);
    b.extend_from_slice(&orientation.to_be_bytes());
    b.extend_from_slice(&[0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    b
}

fn strip_png(src: &[u8]) -> Option<Vec<u8>> {
    let mut rest = src.strip_prefix(&PNG_SIG[..])?;
    let mut out = PNG_SIG.to_vec();
    let mut ended = false;
    while !rest.is_empty() {
        let len = usize::try_from(u32::from_be_bytes(rest.get(..4)?.try_into().ok()?)).ok()?;
        let kind: [u8; 4] = rest.get(4..8)?.try_into().ok()?;
        let total = len.checked_add(12)?;
        let chunk = rest.get(..total)?;
        if !PNG_DROP.contains(&&kind) {
            out.extend_from_slice(chunk);
        }
        ended = &kind == b"IEND";
        rest = &rest[total..];
        if ended {
            break;
        }
    }
    ended.then_some(out)
}

fn strip_webp(src: &[u8]) -> Option<Vec<u8>> {
    if src.get(..4)? != b"RIFF" || src.get(8..12)? != b"WEBP" {
        return None;
    }
    let riff_len = usize::try_from(u32::from_le_bytes(src.get(4..8)?.try_into().ok()?)).ok()?;
    let body = src.get(12..riff_len.checked_add(8)?)?;
    let mut out = b"RIFF\0\0\0\0WEBP".to_vec();
    let mut rest = body;
    while !rest.is_empty() {
        let kind = rest.get(..4)?;
        let len = usize::try_from(u32::from_le_bytes(rest.get(4..8)?.try_into().ok()?)).ok()?;
        let padded = len.checked_add(8)?.checked_add(len & 1)?;
        // The last chunk may lack its pad byte.
        let total = if padded > rest.len() && rest.len() == len + 8 { len + 8 } else { padded };
        let chunk = rest.get(..total)?;
        match kind {
            b"EXIF" | b"XMP " => {}
            b"VP8X" => {
                let mut c = chunk.to_vec();
                *c.get_mut(8)? &= !WEBP_FLAG_EXIF_XMP;
                out.extend_from_slice(&c);
            }
            _ => out.extend_from_slice(chunk),
        }
        rest = &rest[total..];
    }
    let size = u32::try_from(out.len() - 8).ok()?;
    out[4..8].copy_from_slice(&size.to_le_bytes());
    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn segment(marker: u8, body: &[u8]) -> Vec<u8> {
        let mut s = vec![0xFF, marker];
        s.extend_from_slice(&u16::try_from(body.len() + 2).expect("small").to_be_bytes());
        s.extend_from_slice(body);
        s
    }

    /// EXIF with a GPS-looking payload and an orientation entry, little-endian.
    fn exif_with(orientation: u16) -> Vec<u8> {
        let mut b = EXIF_ID.to_vec();
        b.extend_from_slice(b"II\x2A\x00\x08\x00\x00\x00\x01\x00");
        b.extend_from_slice(&TAG_ORIENTATION.to_le_bytes());
        b.extend_from_slice(&[3, 0, 1, 0, 0, 0]);
        b.extend_from_slice(&orientation.to_le_bytes());
        b.extend_from_slice(&[0, 0, 0, 0, 0, 0]);
        b.extend_from_slice(b"GPSLatitude37.5");
        b
    }

    fn jpeg(app1: Option<Vec<u8>>) -> Vec<u8> {
        let mut j = JPEG_SOI.to_vec();
        j.extend(segment(MARKER_APP0, b"JFIF\0\x01\x01\0\0\x01\0\x01\0\0"));
        if let Some(a) = app1 {
            j.extend(segment(MARKER_APP1, &a));
        }
        j.extend(segment(MARKER_COM, b"made by phone"));
        j.extend(segment(0xDB, &[0; 65]));
        j.extend(segment(MARKER_SOS, &[1, 1, 0, 0, 63, 0]));
        j.extend_from_slice(&[0x12, 0x34, 0xFF, 0x00, 0x56, 0xFF, MARKER_EOI]);
        j
    }

    fn has(hay: &[u8], needle: &[u8]) -> bool {
        hay.windows(needle.len()).any(|w| w == needle)
    }

    #[test]
    fn jpeg_loses_gps_and_comment_but_keeps_pixels() {
        let out = strip("jpg", &jpeg(Some(exif_with(1)))).expect("valid jpeg");
        assert!(!has(&out, b"GPSLatitude") && !has(&out, b"made by phone") && !has(&out, EXIF_ID));
        assert!(out.ends_with(&[0x12, 0x34, 0xFF, 0x00, 0x56, 0xFF, MARKER_EOI]), "scan data untouched");
        assert!(has(&out, b"JFIF"));
    }

    #[test]
    fn jpeg_keeps_only_the_orientation() {
        let out = strip("jpg", &jpeg(Some(exif_with(6)))).expect("valid jpeg");
        assert!(!has(&out, b"GPSLatitude"));
        assert_eq!(out[2..4], [0xFF, MARKER_APP1]);
        assert_eq!(exif_orientation(&out[12..]), Some(6), "orientation survives");
        // A second pass changes nothing: the block it wrote is itself valid.
        assert_eq!(strip("jpg", &out).as_deref(), Some(out.as_slice()));
    }

    #[test]
    fn malformed_jpeg_is_refused() {
        let mut j = jpeg(None);
        j.truncate(10);
        assert_eq!(strip("jpg", &j), None);
        assert_eq!(strip("jpg", b"\x00\x01"), None);
    }

    fn chunk(kind: &[u8; 4], data: &[u8]) -> Vec<u8> {
        let mut c = u32::try_from(data.len()).expect("small").to_be_bytes().to_vec();
        c.extend_from_slice(kind);
        c.extend_from_slice(data);
        c.extend_from_slice(&[0, 0, 0, 0]);
        c
    }

    #[test]
    fn png_drops_exif_and_text_chunks() {
        let mut p = PNG_SIG.to_vec();
        p.extend(chunk(b"IHDR", &[0u8; 13]));
        p.extend(chunk(b"eXIf", b"GPSLatitude"));
        p.extend(chunk(b"iTXt", b"XML:com.adobe.xmp"));
        p.extend(chunk(b"IDAT", &[1, 2, 3]));
        p.extend(chunk(b"IEND", &[]));
        let out = strip("png", &p).expect("valid png");
        assert!(!has(&out, b"GPSLatitude") && !has(&out, b"adobe"));
        assert!(has(&out, b"IDAT") && has(&out, b"IHDR") && out.len() < p.len());
        assert_eq!(strip("png", &p[..p.len() - 5]), None, "truncated before IEND");
    }

    fn webp_chunk(kind: &[u8; 4], data: &[u8]) -> Vec<u8> {
        let mut c = kind.to_vec();
        c.extend_from_slice(&u32::try_from(data.len()).expect("small").to_le_bytes());
        c.extend_from_slice(data);
        if data.len() % 2 == 1 {
            c.push(0);
        }
        c
    }

    #[test]
    fn webp_drops_exif_and_xmp_and_clears_flags() {
        let mut body = b"WEBP".to_vec();
        body.extend(webp_chunk(b"VP8X", &[0x2C, 0, 0, 0, 0, 0, 0, 0, 0, 0]));
        body.extend(webp_chunk(b"VP8 ", &[9, 9, 9]));
        body.extend(webp_chunk(b"EXIF", b"GPSLatitude"));
        body.extend(webp_chunk(b"XMP ", b"<x:xmpmeta/>"));
        let mut w = b"RIFF".to_vec();
        w.extend_from_slice(&u32::try_from(body.len()).expect("small").to_le_bytes());
        w.extend(body);
        let out = strip("webp", &w).expect("valid webp");
        assert!(!has(&out, b"GPSLatitude") && !has(&out, b"xmpmeta"));
        assert_eq!(out[20] & WEBP_FLAG_EXIF_XMP, 0, "flags cleared");
        assert_eq!(out[20] & 0x20, 0x20, "ICC flag kept");
        let riff = usize::try_from(u32::from_le_bytes(out[4..8].try_into().expect("4 bytes"))).expect("fits");
        assert_eq!(riff + 8, out.len(), "RIFF size rewritten");
    }

    #[test]
    fn heic_is_not_rewritable() {
        assert_eq!(strip("heic", b"\0\0\0\x18ftypheic"), None);
    }
}
