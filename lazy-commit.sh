#!/bin/bash
cd ~/Documents/fluid46.github.io
# Prompt for commit message
read -rp "Enter commit message: " COMMIT_MESSAGE

# Run git commands
echo "Committing with message: $COMMIT_MESSAGE"
git add .
git commit -m "$COMMIT_MESSAGE"
git push
