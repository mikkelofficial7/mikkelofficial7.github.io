#!/bin/bash
OUTPUT_FILE="result_comment_feedback.json"
echo "[]" > "$OUTPUT_FILE"  # Initialize with an empty JSON array

echo "🔍 Searching for TODO comments in the repository..."

# Find all TODO comments in files
TODO_LINES=$(grep -rIn --exclude-dir={.git,.github,node_modules,vendor} --include=\*.{js,ts,java,kt,php,py,sh} "TODO" . || true)

if [[ -z "$TODO_LINES" ]]; then
    echo "✅ No TODO comments found."
    exit 0
fi

echo "⚠️ Found TODO comments. Adding them to the JSON feedback."

while IFS= read -r line; do
    FILE=$(echo "$line" | cut -d':' -f1)
    LINE_NUM=$(echo "$line" | cut -d':' -f2)
    MESSAGE="⚠️ Found TODO comment. Please address it."

    # Ensure valid JSON structure
    TEMP_FILE="temp.json"
    jq --arg file "$FILE" --arg line "$LINE_NUM" --arg comment "$MESSAGE" \
      '. + [{"file": $file, "line": ($line | tonumber), "comment": $comment}]' \
      "$OUTPUT_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$OUTPUT_FILE"

done <<< "$TODO_LINES"

# Debugging - Check output file
echo "📜 Review comments JSON:"
cat "$OUTPUT_FILE"

# Validate JSON structure
jq empty "$OUTPUT_FILE" || echo "[]" > "$OUTPUT_FILE"
