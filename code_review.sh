#!/bin/bash
OUTPUT_FILE="result_comment_feedback.json"
echo "[]" > "$OUTPUT_FILE"  # Always initialize with an empty JSON array

# Find TODO comments and store them in JSON format
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

# Debugging - Ensure the JSON file is valid
cat "$OUTPUT_FILE" || echo "[]" > "$OUTPUT_FILE"
