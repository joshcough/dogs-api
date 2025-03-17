#!/bin/bash

# Find all PureScript files
FILES=$(find src test -name "*.purs" 2>/dev/null)

# Process each file
for file in $FILES; do
  echo "Formatting $file..."
  purty --write "$file" 2>/dev/null || echo "  Error formatting $file - skipping"
done

echo "Formatting completed."
