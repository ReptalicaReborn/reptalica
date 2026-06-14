#!/bin/bash
# optimize_images.sh
# Resizes images to 800px width and converts to WebP

SRC_FOLDER="assets/original"
DEST_FOLDER="assets/optimized"
TARGET_WIDTH=800
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

convert_to_webp() {
    local src="$1"
    local dest="$2"
    
    if [ -n "$WEBP_TOOL" ]; then
        case "$WEBP_TOOL" in
            magick) magick "$src" -quality "$QUALITY" "$dest" ;;
            convert) convert "$src" -quality "$QUALITY" "$dest" ;;
            cwebp) cwebp -q "$QUALITY" "$src" -o "$dest" ;;
            ffmpeg) ffmpeg -i "$src" -q:v "$QUALITY" -y "$dest" ;;
        esac
        [ -f "$dest" ] && echo "  WebP version created."
    fi
}

TOTAL_SAVED=0

for file in "$SRC_FOLDER"/*.png; do
    [ -f "$file" ] || continue
    
    echo "Processing $(basename "$file")..."
    
    BASENAME=$(basename "$file" .png)
    DEST_PNG="$DEST_FOLDER/${BASENAME}.png"
    DEST_WEBP="$DEST_FOLDER/${BASENAME}.webp"
    
    # Get image dimensions
    WIDTH=$(identify -format "%w" "$file" 2>/dev/null)
    
    if [ "$WIDTH" -gt "$TARGET_WIDTH" ]; then
        OLD_SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        
        # Resize
        if command -v magick &> /dev/null; then
            magick "$file" -resize "${TARGET_WIDTH}x>" "$DEST_PNG"
        elif command -v convert &> /dev/null; then
            convert "$file" -resize "${TARGET_WIDTH}x>" "$DEST_PNG"
        fi
        
        NEW_SIZE=$(stat -f%z "$DEST_PNG" 2>/dev/null || stat -c%s "$DEST_PNG" 2>/dev/null)
        SAVED=$((OLD_SIZE - NEW_SIZE))
        TOTAL_SAVED=$((TOTAL_SAVED + SAVED))
        
        echo "  Resized: ${WIDTH} -> ${TARGET_WIDTH}"
        echo "  Saved: $(echo "scale=2; $SAVED / 1048576" | bc) MB"
        
        convert_to_webp "$DEST_PNG" "$DEST_WEBP"
    else
        echo "  Skipping (already small enough)"
        cp "$file" "$DEST_PNG"
        convert_to_webp "$DEST_PNG" "$DEST_WEBP"
    fi
done

echo "Total space saved: $(echo "scale=2; $TOTAL_SAVED / 1048576" | bc) MB"