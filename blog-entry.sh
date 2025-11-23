#!/bin/bash

BLOGS_DIR="./blogs"
TEMPLATE="$BLOGS_DIR/blog-template.html"

read -rp "Enter blog title: " TITLE

FILENAME=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
DATE=$(date '+%d-%m-%Y')
BLOG_FILE="$BLOGS_DIR/post-$DATE-$FILENAME.html"

TMP_FILE=$(mktemp /tmp/blogbody.XXXXXX)

${EDITOR:-micro} "$TMP_FILE"

BODY=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$TMP_FILE")

sed -e "s/Blog Post Title/$TITLE/" \
    -e "s/YYYY-MM-DD/$DATE/" \
    -e "/Start writing your blog content here.../{
        r $TMP_FILE
        d
    }" "$TEMPLATE" > "$BLOG_FILE"

rm "$TMP_FILE"

echo "Blog post created: $BLOG_FILE"
