# App Icon Setup Instructions

I've created beautiful paw print icons with your app's gradient colors (indigo #6366F1 to purple #8B5CF6)!

## Generated Files

✅ **SVG files created:**
- `assets/icon/app_icon.svg` - Main icon with gradient background
- `assets/icon/app_icon_foreground.svg` - Foreground only (for Android adaptive icon)

## Convert SVG to PNG

You need to convert these SVGs to PNGs. Here are your options:

### Option 1: Online Converter (Easiest)
1. Go to https://cloudconvert.com/svg-to-png
2. Upload `assets/icon/app_icon.svg`
3. Set size to **1024x1024**
4. Download and save as `assets/icon/app_icon.png`
5. Repeat for `app_icon_foreground.svg` → `app_icon_foreground.png`

### Option 2: Using Inkscape (if installed)
```bash
inkscape assets/icon/app_icon.svg --export-png=assets/icon/app_icon.png --export-width=1024
inkscape assets/icon/app_icon_foreground.svg --export-png=assets/icon/app_icon_foreground.png --export-width=1024
```

### Option 3: Using ImageMagick (if installed)
```bash
convert -background none -size 1024x1024 assets/icon/app_icon.svg assets/icon/app_icon.png
convert -background none -size 1024x1024 assets/icon/app_icon_foreground.svg assets/icon/app_icon_foreground.png
```

## Generate App Icons

After converting SVGs to PNGs:

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Generate icons for all platforms:**
   ```bash
   dart run flutter_launcher_icons
   ```

3. **Done!** Your app will now have beautiful paw print icons on:
   - Android (with adaptive icon support)
   - iOS
   - All sizes automatically generated

## What the Icon Looks Like

- **Background**: Gradient from indigo (#6366F1) to purple (#8B5CF6)
- **Foreground**: White paw print with 4 toe pads and main pad
- **Style**: Modern, clean, professional
- **Shape**: Rounded corners (iOS style)

## Troubleshooting

If icons don't appear:
1. Make sure PNG files are 1024x1024
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run `dart run flutter_launcher_icons` again
5. Rebuild your app

## Alternative: Use an Online Icon Generator

If you prefer, you can also use:
- https://www.appicon.co/
- https://easyappicon.com/

Just download the SVG, convert to PNG, and upload!
