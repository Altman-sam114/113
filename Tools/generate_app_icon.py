"""Generate the app's own vector-style mark as opaque launch-icon assets.

This is static asset authoring, not an iOS render or build. Requires Pillow and
NumPy. The SVG source and PNGs share the same geometry and palette.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "LocalGemma/Assets.xcassets/AppIcon.appiconset"
VECTOR = Path(__file__).with_name("Assets") / "AppIcon.svg"
STAR = [
    ((512, 270), (538, 450), (574, 486), (754, 512)),
    ((754, 512), (574, 538), (538, 574), (512, 754)),
    ((512, 754), (486, 574), (450, 538), (270, 512)),
    ((270, 512), (450, 486), (486, 450), (512, 270)),
]


def slots():
    entries = []
    for idiom, sizes in [
        ("iphone", [(20, [2, 3]), (29, [2, 3]), (40, [2, 3]), (60, [2, 3])]),
        ("ipad", [(20, [1, 2]), (29, [1, 2]), (40, [1, 2]), (76, [1, 2]), (83.5, [2])]),
        ("mac", [(16, [1, 2]), (32, [1, 2]), (128, [1, 2]), (256, [1, 2]), (512, [1, 2])]),
        ("ios-marketing", [(1024, [1])]),
    ]:
        for size, scales in sizes:
            for scale in scales:
                pixels = int(size * scale)
                entries.append(dict(idiom=idiom, size=f"{size}x{size}", scale=f"{scale}x",
                                    filename=f"AppIcon-{pixels}.png"))
    return entries


def render():
    scale = 2
    dimension = 1024 * scale
    y, x = np.mgrid[0:dimension, 0:dimension] / scale
    blend = np.clip((x + 1024 - y) / 2048, 0, 1)
    glow = np.exp(-((x - 660) ** 2 + (y - 390) ** 2) / 220000)
    low = np.array([9, 17, 23])
    high = np.array([18, 38, 42])
    pixels = low + blend[..., None] * (high - low) + glow[..., None] * [0, 9, 7]
    image = Image.fromarray(np.uint8(np.clip(pixels, 0, 255)), "RGB")
    draw = ImageDraw.Draw(image)

    def point(px, py):
        return float(px * scale), float(py * scale)

    angle = np.deg2rad(-32)
    orbit = []
    for theta in np.linspace(0, 2 * np.pi, 600):
        px, py = 353 * np.cos(theta), 153 * np.sin(theta)
        orbit.append(point(512 + px * np.cos(angle) - py * np.sin(angle),
                           512 + px * np.sin(angle) + py * np.cos(angle)))
    draw.ellipse((248 * scale, 248 * scale, 776 * scale, 776 * scale),
                 outline=(33, 76, 77), width=3 * scale)
    draw.line(orbit, fill=(80, 155, 151), width=6 * scale)
    points = []
    for segment in STAR:
        p0, p1, p2, p3 = [np.array(p) for p in segment]
        for t in np.linspace(0, 1, 65):
            p = (1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3
            points.append(point(*p))
    draw.polygon(points, fill=(151, 235, 211))
    dot = np.array(orbit[0]) / scale
    draw.ellipse(((dot[0] - 15) * scale, (dot[1] - 15) * scale,
                  (dot[0] + 15) * scale, (dot[1] + 15) * scale), fill=(184, 255, 231))
    return image.resize((1024, 1024), Image.Resampling.LANCZOS)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    VECTOR.parent.mkdir(parents=True, exist_ok=True)
    entries = slots()
    image = render()
    for size in sorted({int(float(item["size"].split("x")[0]) * int(item["scale"][0])) for item in entries}):
        image.resize((size, size), Image.Resampling.LANCZOS).save(OUTPUT / f"AppIcon-{size}.png", optimize=True)
    (OUTPUT / "Contents.json").write_text(json.dumps({"images": entries,
        "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    path = "M 512 270 " + " ".join("C " + " ".join(f"{x} {y}" for x, y in segment[1:]) for segment in STAR) + " Z"
    VECTOR.write_text(f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs><linearGradient id="base" x1="0" y1="1" x2="1" y2="0"><stop stop-color="#091117"/><stop offset="1" stop-color="#12262a"/></linearGradient></defs>
  <path fill="url(#base)" d="M0 0H1024V1024H0Z"/>
  <circle cx="512" cy="512" r="264" fill="none" stroke="#214c4d" stroke-width="3"/>
  <ellipse cx="512" cy="512" rx="353" ry="153" transform="rotate(-32 512 512)" fill="none" stroke="#509b97" stroke-width="6"/>
  <path fill="#97ebd3" d="{path}"/>
  <circle cx="811.36" cy="324.94" r="15" fill="#b8ffe7"/>
</svg>\n''')
    print(f"Generated {len(entries)} icon slots in {OUTPUT}")


if __name__ == "__main__":
    main()
