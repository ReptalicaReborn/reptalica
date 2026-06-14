#!/bin/bash
# convert_webp.sh
# Converts PNG images to WebP format for better web performance.
# Requires: ImageMagick (magick/convert), cwebp, or ffmpeg

FOLDER="assets/thumbnails"
QUALITY=80
RECURSIVE=false
OVERWRITE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--folder) FOLDER="$2"; shift 2 ;;
        -q|--quality) QUALITY="$2"; shift 2 ;;
        -r|--recursive) RECURSIVE=true; shift ;;
        -w|--overwrite) OVERWRITE=true; shift ;;
        *) shift ;;
    esac
done

# Safety check
if [[ "$FOLDER" == *"assets/original"* ]]; then
    echo "Safety Error: This script is restricted from modifying the 'assets/original' folder."
    exit 1
fi

# Find available tool
TOOL=""
if command -v magick &> /dev/null; then
    TOOL="magick"
elif command -v convert &> /dev/null; then
    TOOL="convert"
elif command -v cwebp &> /dev/null; then
    TOOL="cwebp"
elif command -v ffmpeg &> /dev/null; then
    TOOL="ffmpeg"
fi

if [ -z "$TOOL" ]; then
    echo "Error: No conversion tool found. Install ImageMagick, cwebp, or ffmpeg."
    exit 1
fi

echo "Using tool: $TOOL"

# Find PNG files
if [ "$RECURSIVE" = true ]; then
    FILES=$(find "$FOLDER" -name "*.png" -type f 2>/dev/null)
else
    FILES=$(find "$FOLDER" -maxdepth 1 -name "*.png" -type f 2>/dev/null)
fi

if [ -z "$FILES" ]; then
    echo "No PNG files found in $FOLDER."
    exit 0
fi

COUNT=0
while IFS= read -r file; do
    DEST="${file%.png}.webp"
    
    if [ -f "$DEST" ] && [ "$OVERWRITE" = false ]; then
        echo "Skipping $(basename "$file") (WebP already exists)."
        continue
    fi
    
    echo "Converting: $(basename "$file") -> $(basename "$DEST")"
    
    case "$TOOL" in
        magick)
            magick "$file" -quality "$QUALITY" "$DEST" && ((COUNT++)) || echo "Failed: $file"
            ;;
        convert)
            convert "$file" -quality "$QUALITY" "$DEST" && ((COUNT++)) || echo "Failed: $file"
            ;;
        cwebp)
            cwebp -q "$QUALITY" "$file" -o "$DEST" && ((COUNT++)) || echo "Failed: $file"
            ;;
        ffmpeg)
            ffmpeg -i "$file" -q:v "$QUALITY" -y "$DEST" && ((COUNT++)) || echo "Failed: $file"
            ;;
    esac
done <<< "$FILES"

echo "Successfully converted $COUNT files."