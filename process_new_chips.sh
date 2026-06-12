#!/bin/bash
# process_new_chips.sh
# Processes specific new chip images: creates thumbnails and optimized versions

SRC_FOLDER="assets/original"
THUMB_FOLDER="assets/thumbnails"
OPT_FOLDER="assets/optimized"

NEW_FILES=(
    "Helio_G99.png"
    "Moore_Thread_SD102.png"
    "Nvida_Orin.png"
    "Phytium_Tengrui_D3000.jpg"
    "Spacemit_K1.png"
    "Intel_Arrow_Lake_S.png"
)

THUMB_WIDTH=400
OPT_WIDTH=800
QUALITY=80

mkdir -p "$THUMB_FOLDER" "$OPT_FOLDER"

# Find magick/convert
MAGICK=""
if command -v magick &> /dev/null; then
    MAGICK="magick"
elif command -v convert &> /dev/null; then
    MAGICK="convert"
fi

# Find WebP tool
WEBP_TOOL=""
if [ -n "$MAGICK" ]; then
    WEBP_TOOL="$MAGICK"
elif command -v cwebp &> /dev/null; then
    WEBP_TOOL="cwebp"
elif command -v ffmpeg &> /dev/null; then
    WEBP_TOOL="ffmpeg"
fi

convert_to_webp() {
    local src="$1"
    local dest="$2"
    
    if [ -z "$WEBP_TOOL" ]; then
        echo "  Warning: No WebP conversion tool found."
        return
    fi
    
    case "$WEBP_TOOL" in
        magick|convert) "$WEBP_TOOL" "$src" -quality "$QUALITY" "$dest" ;;
        cwebp) cwebp -q "$QUALITY" "$src" -o "$dest" ;;
        ffmpeg) ffmpeg -i "$src" -q:v "$QUALITY" -y "$dest" ;;
    esac
}

resize_and_save() {
    local src="$1"
    local dest="$2"
    local target_width="$3"
    
    local width=$(identify -format "%w" "$src" 2>/dev/null)
    
    if [ "$width" -gt "$target_width" ]; then
        magick "$src" -resize "${target_width}x>" "$dest"
        local new_width=$(identify -format "%w" "$dest" 2>/dev/null)
        echo "  Resized: ${width} -> ${new_width}"
    else
        cp "$src" "$dest"
        echo "  Copied (already <= ${target_width}px)"
    fi
}

for name in "${NEW_FILES[@]}"; do
    SRC="$SRC_FOLDER/$name"
    
    if [ ! -f "$SRC" ]; then
        echo "Warning: Not found: $SRC"
        continue
    fi
    
    STEM="${name%.*}"
    echo ""
    echo "--- $name ---"
    
    # Thumbnail
    THUMB_PNG="$THUMB_FOLDER/${STEM}.png"
    THUMB_WEBP="$THUMB_FOLDER/${STEM}.webp"
    
    if [ -f "$THUMB_WEBP" ]; then
        echo "  Thumbnail WebP already exists, skipping."
    else
        resize_and_save "$SRC" "$THUMB_PNG" "$THUMB_WIDTH"
        convert_to_webp "$THUMB_PNG" "$THUMB_WEBP"
        [ -f "$THUMB_WEBP" ] && echo "  Thumbnail WebP: OK" || echo "  Thumbnail WebP: FAILED"
    fi
    
    # Optimized
    OPT_PNG="$OPT_FOLDER/${STEM}.png"
    OPT_WEBP="$OPT_FOLDER/${STEM}.webp"
    
    if [ -f "$OPT_WEBP" ]; then
        echo "  Optimized WebP already exists, skipping."
    else
        resize_and_save "$SRC" "$OPT_PNG" "$OPT_WIDTH"
        convert_to_webp "$OPT_PNG" "$OPT_WEBP"
        [ -f "$OPT_WEBP" ] && echo "  Optimized WebP: OK" || echo "  Optimized WebP: FAILED"
    fi
done

echo ""
echo "Done."