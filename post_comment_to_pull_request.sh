#!/bin/bash
# This script reads result_comment_feedback.json and posts comments to a GitHub PR.

OUTPUT_FILE="result_comment_feedback.json"

if [[ ! -s "$OUTPUT_FILE" ]]; then
    echo "✅ No comments to post."
    exit 0
fi

echo "📨 Posting comments to GitHub PR..."

# Ensure required environment variables are set
if [[ -z "$GITHUB_TOKEN" || -z "$PR_NUMBER" || -z "$GITHUB_REPOSITORY" ]]; then
    echo "❌ Missing required environment variables."
    exit 1
fi

# Post each comment to GitHub
jq -c '.[]' "$OUTPUT_FILE" | while IFS= read -r line; do
    FILE=$(echo "$line" | jq -r '.file')
    LINE=$(echo "$line" | jq -r '.line')
    COMMENT=$(echo "$line" | jq -r '.comment')

    echo "💬 Commenting on $FILE at line $LINE: $COMMENT"

    curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github.v3+json" \
         -d "{\"body\": \"$COMMENT\", \"path\": \"$FILE\", \"line\": $LINE, \"side\": \"RIGHT\" }" \
         "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER/comments"
done

echo "✅ Review comments posted!"
