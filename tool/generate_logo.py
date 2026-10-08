#!/usr/bin/env python3
"""Navy Sudoku grid for the SudokuNote launcher and splash."""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
NAVY = (47, 62, 158, 255)
WHITE = (255, 255, 255, 255)
PALE = (217, 230, 255, 255)


def draw_mark(canvas: Image.Image, cell: int = 168, gap: int = 28) -> None:
    draw = ImageDraw.Draw(canvas)
    grid = 3 * cell + 2 * gap
    origin = (SIZE - grid) // 2
    filled = {(0, 0), (0, 2), (2, 0), (2, 2)}
    selected = (1, 1)
    radius = 36
    for row in range(3):
        for col in range(3):
            x = origin + col * (cell + gap)
            y = origin + row * (cell + gap)
            box = (x, y, x + cell, y + cell)
            if (row, col) == selected:
                draw.rounded_rectangle(box, radius=radius, fill=PALE)
            elif (row, col) in filled:
                draw.rounded_rectangle(box, radius=radius, fill=WHITE)
            else:
                draw.rounded_rectangle(box, radius=radius, outline=WHITE, width=16)


def splash_icon() -> Image.Image:
    """Android 12 masks this drawable with a circle 2/3 of the canvas. The whole mark stays inside that circle."""
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    plate = 440
    left = (SIZE - plate) // 2
    ImageDraw.Draw(canvas).rounded_rectangle(
        (left, left, left + plate, left + plate),
        radius=88,
        fill=NAVY,
    )
    draw_mark(canvas, cell=96, gap=18)
    return canvas


def main() -> None:
    assets = ROOT / "assets"
    assets.mkdir(exist_ok=True)
    logo = Image.new("RGBA", (SIZE, SIZE), NAVY)
    draw_mark(logo)
    logo.convert("RGB").save(assets / "logo.png", optimize=True)
    splash = splash_icon()
    splash_path = ROOT / "android/app/src/main/res/drawable-nodpi/splash_icon.png"
    splash_path.parent.mkdir(parents=True, exist_ok=True)
    splash.save(splash_path, optimize=True)
    print(f"wrote {assets / 'logo.png'}")
    print(f"wrote {splash_path}")


if __name__ == "__main__":
    main()
