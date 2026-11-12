// Production bootstrap for both Flutter web builds (copied into apps/*/web/ by deploy/web.Dockerfile only).
// Keeps the browser on our own origin so the CSP in deploy/Caddyfile needs no Google host.
{{flutter_js}}
{{flutter_build_config}}

// The google_sign_in web plugin injects Google's sign-in script the moment it registers, although the web
// builds offer no social sign-in (native apps only). Drop that one tag before the browser requests it.
// shortcut: patches document.head.appendChild; remove once the web builds no longer register google_sign_in_web.
const appendToHead = document.head.appendChild;
document.head.appendChild = function (node) {
  return node.src === "https://accounts.google.com/gsi/client" ? node : appendToHead.call(this, node);
};

// Fallback fonts (Roboto + Noto: Korean, Japanese, Thai, Khmer, Sinhala, emoji...) come from the image's own
// /webfonts/ mirror instead of fonts.gstatic.com. Local dev keeps Flutter's default.
_flutter.loader.load({ config: { fontFallbackBaseUrl: "/webfonts/" } });
