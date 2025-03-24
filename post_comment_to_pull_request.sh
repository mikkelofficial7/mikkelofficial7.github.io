#!/bin/bash
OUTPUT_FILE="result_comment_feedback.json"

if [[ ! -s "$OUTPUT_FILE" ]]; then
    echo "✅ No comments to post."
    exit 0
fi

echo "📨 Posting comments to GitHub PR..."

if [[ -z "$GITHUB_TOKEN" || -z "$PR_NUMBER" || -z "$GITHUB_REPOSITORY" ]]; then
    echo "❌ Missing required environment variables."
    exit 1
fi

COMMENTS_JSON=$(jq -c '[.[] | {path: .file, position: .line | tonumber, body: .comment}]' "$OUTPUT_FILE")

# Create a GitHub PR review with inline comments + "This is comment"
REVIEW_PAYLOAD=$(jq -n \
  --argjson comments "$COMMENTS_JSON" \
  --arg final_comment "This is comment" \
  '{body: $final_comment, event: "COMMENT", comments: $comments}')

echo "📨 Sending review payload:"
echo "$REVIEW_PAYLOAD"

curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     -d "$REVIEW_PAYLOAD" \
     "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER/reviews"

echo "✅ Review posted!"
