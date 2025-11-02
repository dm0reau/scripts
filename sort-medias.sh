#!/bin/bash

# Requires exiftool
# Usage: ./sort-photos.sh [SRC_DIR] [DEST_DIR]

if [ $# -lt 2 ]; then
    echo "Usage: $0 <SRC_DIR> <DEST_DIR>"
    echo "Example: $0 /path/to/photos /path/to/sorted-photos"
    exit 1
fi

SRC_DIR="$1"
DEST_DIR="$2"

mkdir -p "$DEST_DIR"

FINDED_FILES_COUNT=0
SORTED_FILES_COUNT=0

while IFS= read -r FILE; do
    let FINDED_FILES_COUNT++

    # Try to get date from EXIF
    DATE=$(exiftool -d "%Y/%m" -DateTimeOriginal "$FILE" 2>/dev/null | awk -F': ' '{print $2}')
    echo "Processing $FILE, extracted date from exiftool: $DATE"

    if [[ -z "$DATE" ]]; then
        # Extract date from file name as fallback (assuming format IMG_YYYYMMDD_...)
        BASENAME=$(basename "$FILE")
        if [[ $BASENAME =~ ([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
            YEAR=${BASH_REMATCH[1]}
            MONTH=${BASH_REMATCH[2]}
            DATE="$YEAR/$MONTH"
        fi
        if [[ -n "$YEAR" && -n "$MONTH" ]]; then
            DATE="$YEAR/$MONTH"
        fi

        echo "No EXIF date found, extracting date from file name: $DATE"
    fi

    if [[ -z "$DATE" ]]; then
        echo "Could not determine date for $FILE. Placing in 'unsorted' folder."
        TARGET_DIR="$DEST_DIR/unsorted"
    else
        TARGET_DIR="$DEST_DIR/$DATE"
        let SORTED_FILES_COUNT++
    fi

    mkdir -p "$TARGET_DIR"
    mv "$FILE" "$TARGET_DIR/"
    
done < <(find "$SRC_DIR" -type f \
    \( -iname "*.jpg" \
    -o -iname "*.jpeg" \
    -o -iname "*.png" \
    -o -iname "*.heic" \
    -o -iname "*.mov" \
    -o -iname "*.mp4" \
    -o -iname "*.avi" \
    -o -iname "*.mkv" \
    -o -iname "*.m4v" \
    -o -iname "*.mpg" \
    -o -iname "*.mpeg" \))

printf "\n\nFinal Summary:\n\n"
echo "Number of files in source directory: ${FINDED_FILES_COUNT}"
echo "Total files sorted: ${SORTED_FILES_COUNT}"