#!/bin/bash
# create_thumbnails.sh
# Creates 400px thumbnails from original images and converts to WebP

SRC_FOLDER="assets/original"
DEST_FOLDER="assets/thumbnails"
TARGET_WIDTH=400
QUALITY=80

mkdir -p "$DEST_FOLDER"

# Find available WebP tool
WEBP_TOOL=""
if command -v magick &> /dev/null; then
    WEBP_TOOL="magick"
elif command -v convert &> /dev/null; then
    WEBP_TOOL="convert"
elif command -v cwebp &> /dev/null; then
    WEBP_TOOL="cwebp"
elif command -v ffmpeg &> /dev/null; then
    WEBP_TOOL="ffmpeg"
fi

TOTAL_SAVED=0

for file in "$SRC_FOLDER"/*.png; do
    [ -f "$file" ] || continue
    
    echo "Creating thumbnail for $(basename "$file")..."
    
    # Get original size
    OLD_SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    
    # Resize with ImageMagick
    BASENAME=$(basename "$file" .png)
    DEST_PNG="$DEST_FOLDER/${BASENAME}.png"
    DEST_WEBP="$DEST_FOLDER/${BASENAME}.webp"
    
    if command -v magick &> /dev/null; then
        magick "$file" -resize "${TARGET_WIDTH}x>" "$DEST_PNG"
    elif command -v convert &> /dev/null; then
        convert "$file" -resize "${TARGET_WIDTH}x>" "$DEST_PNG"
    else
        echo "Error: ImageMagick not found for resizing."
        exit 1
    fi
    
    # Get new size
    NEW_SIZE=$(stat -f%z "$DEST_PNG" 2>/dev/null || stat -c%s "$DEST_PNG" 2>/dev/null)
    SAVED=$((OLD_SIZE - NEW_SIZE))
    TOTAL_SAVED=$((TOTAL_SAVED + SAVED))
    
    echo "  Resized to ${TARGET_WIDTH}px width"
    echo "  Saved: $(echo "scale=2; $SAVED / 1048576" | bc) MB"
    
    # Convert to WebP if tool available
    if [ -n "$WEBP_TOOL" ]; then
        case "$WEBP_TOOL" in
            magick) magick "$DEST_PNG" -quality "$QUALITY" "$DEST_WEBP" ;;
            convert) convert "$DEST_PNG" -quality "$QUALITY" "$DEST_WEBP" ;;
            cwebp) cwebp -q "$QUALITY" "$DEST_PNG" -o "$DEST_WEBP" ;;
            ffmpeg) ffmpeg -i "$DEST_PNG" -q:v "$QUALITY" -y "$DEST_WEBP" ;;
        esac
        [ -f "$DEST_WEBP" ] && echo "  WebP version created."
    fi
done

echo "Total space saved for thumbnails: $(echo "scale=2; $TOTAL_SAVED / 1048576" | bc) MB"