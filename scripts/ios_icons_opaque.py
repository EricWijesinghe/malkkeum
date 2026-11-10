"""App Store rejects app icons with an alpha channel: flatten every iOS AppIcon PNG to RGB."""
import pathlib
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent / "app" / "apps"
for png in ROOT.glob("*/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png"):
    img = Image.open(png)
    if img.mode != "RGB":
        bg = Image.new("RGB", img.size, (59, 91, 253))
        bg.paste(img, mask=img.split()[-1] if img.mode in ("RGBA", "LA") else None)
        bg.save(png, optimize=True)
print("ok")
