#!/bin/bash

# Configuration
POSTS_PER_PAGE=3
PREVIEW_WORDS=20
BLOGS_DIR="blogs"

# Create blogs directory if it doesn't exist
mkdir -p "$BLOGS_DIR"

# Function to get current date and time
get_datetime() {
    date '+%d/%m/%y %H:%M'
}

# Function to get filename date format
get_filename_date() {
    date '+%d-%m-%Y-%H:%M'
}

# Function to extract preview from content
get_preview() {
    local content="$1"
    echo "$content" | sed 's/<[^>]*>//g' | tr '\n' ' ' | awk -v words="$PREVIEW_WORDS" '{
        for(i=1; i<=words && i<=NF; i++) printf "%s ", $i
        if(NF > words) printf "..."
    }'
}

# Function to create blog post template
create_blog_template() {
    local title="$1"
    local date="$2"
    local filename="$3"
    
    cat > "$filename" << EOF
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>$title - F L U I D 4 6</title>
<link rel="icon" type="image/gif" href="../assets/favicon.gif">
<link href="../css/style.css" rel="stylesheet" type="text/css" media="all">
<style>
section {
    width: 500px;
}
article {
    width: 460px;
}
</style>
</head>

<body>
<section>
<img src="../assets/fish.gif" width="141" height="92" /><br /><br /><br />
<div class="clearfix">
    <header>
      La Mer
    </header>
    <nav>
    <a href="../index.html">&bull;</a> <a href="../blog.html">&bull;</a> <a href="../contact.html">&bull;</a> 
    </nav>
</div>

<article>
<h1>&bull; $title</h1><h2>$date</h2>
<p><br />
<!-- Write your blog content here -->

</p>
</article>

<footer>
    <a href="../index.html">← Back to Home</a>
</footer>
</section>

<footerb>
<img src="../assets/gnunano.gif" />
<img src="../assets/dbd.gif" />
<img src="../assets/github.gif" />
<img src="../assets/grapheneos.gif" />
<img src="../assets/NO_JS.gif" />
<img src="../assets/SMILE.png" />
</footerb>
</body>
</html>
EOF
}

# Function to rebuild all pages
rebuild_pages() {
    # Get all blog posts sorted by date (newest first)
    local posts=()
    while IFS= read -r -d '' file; do
        posts+=("$file")
    done < <(find "$BLOGS_DIR" -name "*.html" -print0 | sort -z -r)
    
    local total_posts=${#posts[@]}
    local total_pages=$(( (total_posts + POSTS_PER_PAGE - 1) / POSTS_PER_PAGE ))
    
    if [ $total_pages -eq 0 ]; then
        total_pages=1
    fi
    
    # Generate index.html (page 1)
    generate_page_content 1 "$total_pages" "${posts[@]:0:$POSTS_PER_PAGE}" > index.html
    
    # Generate additional pages if needed
    for ((page=2; page<=total_pages; page++)); do
        local start_idx=$(( (page - 1) * POSTS_PER_PAGE ))
        local page_posts=("${posts[@]:$start_idx:$POSTS_PER_PAGE}")
        generate_page_content "$page" "$total_pages" "${page_posts[@]}" > "page$page.html"
    done
    
    # Remove any extra page files
    for ((page=total_pages+1; page<=20; page++)); do
        [ -f "page$page.html" ] && rm "page$page.html"
    done
}

# Function to extract content from HTML file
extract_content_from_html() {
    local file="$1"
    # Extract content between <p><br /> and </p> tags
    sed -n '/<p><br \/>/,/<\/p>/p' "$file" | sed '1d;$d' | sed '/^$/d'
}

# Function to generate page content
generate_page_content() {
    local current_page="$1"
    local total_pages="$2"
    shift 2
    local posts=("$@")
    
    cat << 'EOF'
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>F L U I D 4 6</title>
<link rel="icon" type="image/gif" href="assets/favicon.gif">
<link href="css/style.css" rel="stylesheet" type="text/css" media="all">
</head>

<body>
<section>
<img src="assets/fish.gif" width="141" height="92" /><br /><br /><br />
<div class="clearfix">
	<header>
	  La Mer
	</header>
	<nav>
	<a href="index.html">&bull;</a> <a href="blog.html">&bull;</a> <a href="contact.html">&bull;</a> 
	</nav>
</div>
<blog>
EOF

    # Generate articles for this page
    for post_file in "${posts[@]}"; do
        if [ -f "$post_file" ]; then
            local basename=$(basename "$post_file" .html)
            local title=$(echo "$basename" | cut -d'-' -f1)
            local date_part=$(echo "$basename" | cut -d'-' -f2-)
            local formatted_date=$(echo "$date_part" | sed 's/-/\//g' | sed 's/:/ /')
            local content=$(extract_content_from_html "$post_file")
            local preview=$(get_preview "$content")
            local relative_path="blogs/$basename.html"
            
            # Add article to current page
            cat << EOF

	<article>
	<h1>&bull; <a href="$relative_path" style="color: #333; text-decoration: none;">$title</a></h1><h2>$formatted_date</h2>
	<p><br />
	$preview
	</p>
	</article>
EOF
        fi
    done

    # Generate pagination
    local prev_link="index.html"
    local next_link="index.html"
    
    if [ "$current_page" -gt 1 ]; then
        if [ "$current_page" -eq 2 ]; then
            prev_link="index.html"
        else
            prev_link="page$((current_page-1)).html"
        fi
    fi
    
    if [ "$current_page" -lt "$total_pages" ]; then
        next_link="page$((current_page+1)).html"
    fi

    cat << EOF
</blog>
<footer>
	<a href="$prev_link"><</a> 
	<span>Page $current_page</span>
	<a href="$next_link">></a>
</footer>
</section>

<footerb>
<img src="assets/gnunano.gif" />
<img src="assets/dbd.gif" />
<img src="assets/github.gif" />
<img src="assets/grapheneos.gif" />
<img src="assets/NO_JS.gif" />
<img src="assets/SMILE.png" />
</footerb>
</body>
</html>
EOF
}

# Main script execution
echo "=== Blog Post Creator ==="
read -rp "Enter post title: " TITLE

if [ -z "$TITLE" ]; then
    echo "Error: Title cannot be empty"
    exit 1
fi

# Create filename
FILENAME_DATE=$(get_filename_date)
BLOG_FILE="$BLOGS_DIR/${TITLE}-${FILENAME_DATE}.html"
CURRENT_DATE=$(get_datetime)

echo "Creating blog post: $BLOG_FILE"

# Create the blog template
create_blog_template "$TITLE" "$CURRENT_DATE" "$BLOG_FILE"

echo "Opening micro editor..."

# Open micro editor
micro "$BLOG_FILE"

# Check if file was created and has content
if [ ! -f "$BLOG_FILE" ]; then
    echo "Blog post creation cancelled."
    exit 1
fi

echo "Blog post created successfully!"
echo "Rebuilding pages..."

# Rebuild all pages
rebuild_pages

echo "Blog updated! Check index.html for the latest posts."