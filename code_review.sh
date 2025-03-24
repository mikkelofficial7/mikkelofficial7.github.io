#!/bin/bash
OUTPUT_FILE="result_comment_feedback.json"
echo "[]" > "$OUTPUT_FILE"  # Initialize with an empty JSON array

echo "🔍 Detecting changed files..."
CHANGED_FILES=$(git diff --name-only HEAD^ HEAD || true)

if [[ -z "$CHANGED_FILES" ]]; then
    echo "✅ No changed files detected."
    exit 0
fi

echo "📂 Scanning changed files..."
for FILE in $CHANGED_FILES; do
    # Skip binary files
    if file "$FILE" | grep -qE 'binary'; then
        echo "🚫 Skipping binary file: $FILE"
        continue
    fi

    # Check for TODO comments
    while IFS= read -r line; do
        LINE_NUM=$(echo "$line" | cut -d':' -f1)
        MESSAGE="⚠️ Found TODO comment. Please address it."

        # Append JSON entry
        TEMP_FILE="temp.json"
        jq --arg file "$FILE" --arg line "$LINE_NUM" --arg comment "$MESSAGE" \
          '. + [{"file": $file, "line": ($line | tonumber), "comment": $comment}]' \
          "$OUTPUT_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$OUTPUT_FILE"

    done <<< "$(grep -n "TODO" "$FILE" || true)"

    # Check for missing function comments (for Python, Java, JS, etc.)
    if grep -qE 'def |function |class ' "$FILE"; then
        while IFS= read -r line; do
            LINE_NUM=$(echo "$line" | cut -d':' -f1)
            FUNC_NAME=$(echo "$line" | awk '{print $2}')
            MESSAGE="⚠️ Function/Class '$FUNC_NAME' lacks a docstring. Please add a comment."

            # Append JSON entry
            jq --arg file "$FILE" --arg line "$LINE_NUM" --arg comment "$MESSAGE" \
              '. + [{"file": $file, "line": ($line | tonumber), "comment": $comment}]' \
              "$OUTPUT_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$OUTPUT_FILE"

        done <<< "$(grep -nE 'def |function |class ' "$FILE" | grep -v '"""' || true)"
    fi
done

# Debugging output
echo "📜 Review comments JSON:"
cat "$OUTPUT_FILE"

# Validate JSON
jq empty "$OUTPUT_FILE" || echo "[]" > "$OUTPUT_FILE"
