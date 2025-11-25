#!/usr/bin/env python3
"""
Generate WalkMyPet app icon with paw logo
Uses PIL/Pillow to create a gradient background with paw print
"""

try:
    from PIL import Image, ImageDraw
    import math
except ImportError:
    print("Installing required packages...")
    import subprocess
    subprocess.check_call(['pip3', 'install', 'pillow'])
    from PIL import Image, ImageDraw
    import math


def create_gradient(width, height, color1, color2):
    """Create a diagonal gradient from top-left to bottom-right"""
    base = Image.new('RGB', (width, height), color1)
    top = Image.new('RGB', (width, height), color2)
    mask = Image.new('L', (width, height))
    mask_data = []
    for y in range(height):
        for x in range(width):
            # Diagonal gradient
            distance = math.sqrt(x**2 + y**2) / math.sqrt(width**2 + height**2)
            mask_data.append(int(255 * distance))
    mask.putdata(mask_data)
    base.paste(top, (0, 0), mask)
    return base


def draw_paw(draw, cx, cy, size, color):
    """Draw a paw print with main pad and 4 toe pads"""
    # Main pad (larger, bottom)
    pad_width = size * 0.6
    pad_height = size * 0.5
    main_pad = [
        (cx - pad_width/2, cy + size*0.15),
        (cx + pad_width/2, cy + size*0.15),
        (cx + pad_width/2, cy + size*0.55),
        (cx - pad_width/2, cy + size*0.55),
    ]
    draw.ellipse([
        cx - pad_width/2, cy + size*0.15,
        cx + pad_width/2, cy + size*0.65
    ], fill=color)

    # Toe pads (4 smaller ovals above main pad)
    toe_size = size * 0.22
    toe_positions = [
        (cx - size*0.35, cy - size*0.15),  # Left toe
        (cx - size*0.12, cy - size*0.35),  # Left-center toe
        (cx + size*0.12, cy - size*0.35),  # Right-center toe
        (cx + size*0.35, cy - size*0.15),  # Right toe
    ]

    for tx, ty in toe_positions:
        draw.ellipse([
            tx - toe_size/2, ty - toe_size/2,
            tx + toe_size/2, ty + toe_size/2
        ], fill=color)


def create_icon(size, output_path, foreground_only=False):
    """Create app icon with gradient background and white paw"""
    if foreground_only:
        # Transparent background for adaptive icon foreground
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    else:
        # Gradient background: #6366F1 (indigo) to #8B5CF6 (purple)
        img = create_gradient(size, size, (99, 102, 241), (139, 92, 246))
        img = img.convert('RGBA')

    draw = ImageDraw.Draw(img)

    # Draw white paw in center
    center_x = size / 2
    center_y = size / 2
    paw_size = size * 0.45

    draw_paw(draw, center_x, center_y, paw_size, (255, 255, 255, 255))

    return img


def main():
    print("🐾 Generating WalkMyPet app icons...")

    # Create main icon (1024x1024 for iOS, will be resized by flutter_launcher_icons)
    print("Creating main icon (1024x1024)...")
    icon_1024 = create_icon(1024, "assets/icon/app_icon.png")
    icon_1024.save("assets/icon/app_icon.png", "PNG")

    # Create adaptive icon foreground (transparent background)
    print("Creating adaptive icon foreground (1024x1024)...")
    foreground = create_icon(1024, "assets/icon/app_icon_foreground.png", foreground_only=True)
    foreground.save("assets/icon/app_icon_foreground.png", "PNG")

    print("✅ Icons generated successfully!")
    print("📁 Saved to:")
    print("   - assets/icon/app_icon.png")
    print("   - assets/icon/app_icon_foreground.png")
    print("\nNext step: Run 'flutter pub get' then 'dart run flutter_launcher_icons'")


if __name__ == "__main__":
    main()
