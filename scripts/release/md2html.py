"""Renders one Markdown file to a standalone HTML page (stdlib only, no network).

  python -I scripts/release/md2html.py <in.md> <out.html> "<page title>"

Covers what the Malkkeum guides use: headings, paragraphs, lists, tables, fenced code,
blockquotes, bold, inline code and links. Anything else is escaped and shown as text.
"""
import html
import re
import sys
from pathlib import Path

CSS = """
body{font-family:"Malgun Gothic","Segoe UI",system-ui,sans-serif;max-width:860px;margin:2rem auto;
padding:0 1rem;line-height:1.6;color:#1d1d1f}
h1,h2,h3{line-height:1.25}h1{border-bottom:2px solid #7c5cff;padding-bottom:.3rem}
code,pre{font-family:Consolas,monospace;background:#f3f3f7;border-radius:4px}
code{padding:.1rem .3rem}pre{padding:.8rem;overflow-x:auto}pre code{padding:0}
table{border-collapse:collapse;margin:1rem 0;width:100%}
th,td{border:1px solid #d6d6de;padding:.4rem .6rem;text-align:left;vertical-align:top}
th{background:#f3f3f7}blockquote{border-left:4px solid #7c5cff;margin:1rem 0;padding:.2rem 1rem;color:#444}
a{color:#5b3fd6}
@media (prefers-color-scheme: dark){body{background:#16161a;color:#eaeaf0}code,pre,th{background:#26262e}
th,td{border-color:#3a3a46}blockquote{color:#c8c8d0}a{color:#b7a6ff}}
"""

def inline(text):
    # Escape first, then apply markup. Code spans are protected so their contents stay literal.
    parts = re.split(r"(`[^`]+`)", text)
    out = []
    for part in parts:
        if part.startswith("`") and part.endswith("`") and len(part) > 1:
            out.append("<code>" + html.escape(part[1:-1]) + "</code>")
            continue
        s = html.escape(part, quote=False)
        s = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", lambda m: f'<a href="{m.group(2)}">{m.group(1)}</a>', s)
        s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
        out.append(s)
    return "".join(out)


def table_cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def render(src):
    lines = src.splitlines()
    out, i = [], 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if stripped.startswith("```"):
            code = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code.append(lines[i])
                i += 1
            out.append("<pre><code>" + html.escape("\n".join(code)) + "</code></pre>")
        elif re.match(r"^#{1,6} ", stripped):
            level = len(stripped) - len(stripped.lstrip("#"))
            out.append(f"<h{level}>{inline(stripped[level + 1:])}</h{level}>")
        elif stripped.startswith("|") and i + 1 < len(lines) and re.match(r"^\|?\s*:?-{2,}", lines[i + 1].strip()):
            head = table_cells(line)
            out.append("<table><thead><tr>" + "".join(f"<th>{inline(c)}</th>" for c in head) + "</tr></thead><tbody>")
            i += 2
            while i < len(lines) and lines[i].strip().startswith("|"):
                out.append("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in table_cells(lines[i])) + "</tr>")
                i += 1
            out.append("</tbody></table>")
            continue
        elif re.match(r"^[-*] ", stripped) or re.match(r"^\d+\. ", stripped):
            ordered = bool(re.match(r"^\d+\. ", stripped))
            tag = "ol" if ordered else "ul"
            out.append(f"<{tag}>")
            while i < len(lines) and re.match(r"^\s*([-*]|\d+\.) ", lines[i]):
                item = re.sub(r"^\s*([-*]|\d+\.) ", "", lines[i])
                out.append(f"<li>{inline(item)}</li>")
                i += 1
            out.append(f"</{tag}>")
            continue
        elif stripped.startswith(">"):
            quote = []
            while i < len(lines) and lines[i].strip().startswith(">"):
                quote.append(lines[i].strip()[1:].strip())
                i += 1
            out.append("<blockquote>" + "<br>".join(inline(q) for q in quote) + "</blockquote>")
            continue
        elif stripped in ("---", "***"):
            out.append("<hr>")
        elif stripped:
            para = [stripped]
            i += 1
            while i < len(lines) and lines[i].strip() and not re.match(r"^(#|```|[-*] |\d+\. |\||>)", lines[i].strip()):
                para.append(lines[i].strip())
                i += 1
            out.append(f"<p>{inline(' '.join(para))}</p>")
            continue
        i += 1
    return "\n".join(out)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    src_path, dst_path, title = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
    body = render(src_path.read_text(encoding="utf-8"))
    page = (
        '<!doctype html><html lang="ko"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        f"<title>{html.escape(title)}</title><style>{CSS}</style></head><body>\n"
        f"{body}\n</body></html>\n"
    )
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    dst_path.write_text(page, encoding="utf-8")


if __name__ == "__main__":
    main()
