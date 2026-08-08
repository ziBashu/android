"""Export MorphOS ziBashu-branded launcher icons into Android res/."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\syxMa\.grok\sessions\C%3A%5CUsers%5CsyxMa%5CANDROID"
    r"\019fd4e3-e708-7753-9374-2146ffb8c077\images\2.jpg"
)
BRAND = ROOT / "assets" / "brand"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

INK = (20, 20, 20, 255)


def make_foreground(master: Image.Image, size: int) -> Image.Image:
    """Adaptive icon foreground: ink canvas + artwork in safe zone."""
    fg = Image.new("RGBA", (size, size), INK)
    content = max(1, int(size * 0.72))
    art = master.resize((content, content), Image.Resampling.LANCZOS)
    ox = (size - content) // 2
    oy = (size - content) // 2
    fg.paste(art, (ox, oy), art)
    return fg


def main() -> None:
    if not SRC.is_file():
        raise SystemExit(f"Missing source icon: {SRC}")

    BRAND.mkdir(parents=True, exist_ok=True)
    img = Image.open(SRC).convert("RGBA")
    master = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    master_path = BRAND / "morphos_launcher_1024.png"
    master.save(master_path, "PNG")
    print("master", master_path)

    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in densities.items():
        out_dir = RES / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        icon = master.resize((size, size), Image.Resampling.LANCZOS)
        icon.save(out_dir / "ic_launcher.png", "PNG")
        icon.save(out_dir / "ic_launcher_round.png", "PNG")
        print(folder, size)

    fg_sizes = {
        "drawable-mdpi": 108,
        "drawable-hdpi": 162,
        "drawable-xhdpi": 216,
        "drawable-xxhdpi": 324,
        "drawable-xxxhdpi": 432,
    }
    for folder, size in fg_sizes.items():
        d = RES / folder
        d.mkdir(parents=True, exist_ok=True)
        make_foreground(master, size).save(d / "ic_launcher_foreground.png", "PNG")
        Image.new("RGBA", (size, size), INK).save(
            d / "ic_launcher_background.png", "PNG"
        )
        print("adaptive", folder, size)

    make_foreground(master, 432).save(
        BRAND / "morphos_adaptive_foreground.png", "PNG"
    )
    print("done")


if __name__ == "__main__":
    main()
