#!/bin/bash
OUTPUT_FILE="review_output.json"
echo "[]" > "$OUTPUT_FILE"  # Initialize with empty JSON array

while IFS= read -r line; do
    FILE=$(echo "$line" | cut -d':' -f1)
    LINE_NUM=$(echo "$line" | cut -d':' -f2)
    MESSAGE="⚠️ Found TODO comment. Please address it."

    # Append JSON object safely
    TEMP_FILE="temp.json"
    jq --arg file "$FILE" --arg line "$LINE_NUM" --arg comment "$MESSAGE" \
      '. + [{"file": $file, "line": ($line | tonumber), "comment": $comment}]' \
      "$OUTPUT_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$OUTPUT_FILE"
done < <(grep -rnw '.' -e "TODO" || true)