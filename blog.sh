#!/bin/bash

# Configuration
BLOG_DIR="$HOME/fluid46.github.io/blog"
SITE_DIR="$HOME/fluid46.github.io"
TEMP_FILE="/tmp/blog_temp.md"

# Ensure blog directory exists
mkdir -p "$BLOG_DIR"

# Get current date in DD-MM-YYYY format
CURRENT_DATE=$(date +"%d-%m-%Y")

# Ask for blog title
echo "Enter blog post title:"
read -r TITLE

# Create filename with date and title (replace spaces with hyphens, remove special chars)
FILENAME="${CURRENT_DATE}-$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g').md"
FILEPATH="$BLOG_DIR/$FILENAME"

# Create temporary file with title
echo "$TITLE" > "$TEMP_FILE"
echo "" >> "$TEMP_FILE"

# Open micro editor for content
echo "Opening micro editor for blog content..."
micro "$TEMP_FILE"

# Read the content
BLOG_TITLE=$(head -n 1 "$TEMP_FILE")
BLOG_CONTENT=$(tail -n +3 "$TEMP_FILE")

# Move temp file to blog directory
mv "$TEMP_FILE" "$FILEPATH"

echo "Blog post created: $FILEPATH"

# Function to update blog.html with all posts
update_blog_html() {
    cat > "$SITE_DIR/blog.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Blog Archive</title>
    <style>
        body { 
            background-color: #EEE1C6; 
            font-family: monospace; 
            color: #4E3524;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        .box {
            background-color: #f8f4e9;
            border: 1px solid #d4c9a8;
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
        }
        a {
            color: #4E3524;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="box">
        <h1>Blog Archive</h1>
EOF

    # Add all blog posts to blog.html (newest first)
    for file in $(ls -t "$BLOG_DIR"/*.md 2>/dev/null); do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            title=$(head -n 1 "$file")
            echo "        <h2><a href=\"blog/$filename\">$title</a></h2>" >> "$SITE_DIR/blog.html"
        fi
    done

    cat >> "$SITE_DIR/blog.html" << 'EOF'
    </div>
</body>
</html>
EOF
}

# Function to update index.html with 3 most recent posts
update_index_html() {
    # Read the current index.html
    if [ ! -f "$SITE_DIR/index.html" ]; then
        echo "Error: index.html not found in $SITE_DIR"
        return 1
    fi

    # Create temporary file for new index.html
    TEMP_INDEX="/tmp/index_temp.html"
    
    # Read index.html and replace content between <blog> tags
    awk '
    BEGIN { in_blog = 0; blog_content = "" }
    /<blog>/ { 
        in_blog = 1; 
        print $0;
        next 
    }
    /<\/blog>/ { 
        in_blog = 0;
        print blog_content;
        print $0;
        next 
    }
    !in_blog { print $0 }
    ' "$SITE_DIR/index.html" > "$TEMP_INDEX"

    # Now we need to insert the blog content
    # Get the 3 most recent blog posts
    RECENT_POSTS=$(ls -t "$BLOG_DIR"/*.md 2>/dev/null | head -3)
    
    # Generate blog content for index.html
    BLOG_HTML=""
    COUNTER=1
    
    for file in $RECENT_POSTS; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            title=$(head -n 1 "$file")
            content=$(tail -n +3 "$file" | head -c 200)  # First 200 chars
            date_part=$(echo "$filename" | cut -d'-' -f1-3)
            
            # Convert DD-MM-YYYY to DD/MM/YY format
            day=$(echo "$date_part" | cut -d'-' -f1)
            month=$(echo "$date_part" | cut -d'-' -f2)
            year=$(echo "$date_part" | cut -d'-' -f3 | cut -c3-4)
            formatted_date="$day/$month/$year 00:00"
            
            BLOG_HTML="$BLOG_HTML
	<article>
	<h1>&bull; $title</h1><h2>$formatted_date</h2>
	<p><br />
	$content...
	</p>
	</article>"
        fi
        COUNTER=$((COUNTER + 1))
    done

    # Replace the blog section in the temp file
    awk -v blog_content="$BLOG_HTML" '
    BEGIN { in_blog = 0 }
    /<blog>/ { 
        in_blog = 1; 
        print $0;
        print blog_content;
        next 
    }
    /<\/blog>/ { 
        in_blog = 0;
        print $0;
        next 
    }
    !in_blog { print $0 }
    ' "$SITE_DIR/index.html" > "$TEMP_INDEX"

    # Replace original with updated version
    mv "$TEMP_INDEX" "$SITE_DIR/index.html"
}

# Update both files
echo "Updating blog.html..."
update_blog_html

echo "Updating index.html..."
update_index_html

echo "Blog system updated successfully!"
echo "New post: $BLOG_TITLE"
echo "File: $FILENAME"