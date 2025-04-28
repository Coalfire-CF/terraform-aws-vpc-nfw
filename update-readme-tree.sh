#!/bin/bash

# Read configuration from readmetreerc.yml
if [ -f readmetreerc.yml ]; then
  file_names=$(grep -A5 "fileNames:" readmetreerc.yml | grep -v "fileNames:" | sed 's/^[ \t]*-[ \t]*//' | tr -d ' ')
  chapter=$(grep "chapter:" readmetreerc.yml | cut -d':' -f2 | tr -d ' ')
  include_dirs=$(grep -A5 "include:" readmetreerc.yml | grep -v "include:" | sed 's/^[ \t]*-[ \t]*//' | tr -d ' ' | tr '\n' ' ')
else
  file_names="README.md"
  chapter="Tree"
  include_dirs="."
fi

# Generate tree structure with the exact format required
tree_output=$(tree -a -I ".git|node_modules|.github" --noreport --charset ascii .)

# Format the tree with asterisks instead of pipe characters and create proper markdown links
formatted_tree=$(echo "$tree_output" | 
  # Replace the first line with just a dot
  sed '1s/^.*$/\./' |
  # Replace the tree symbols with proper bullet points and indentation
  sed -E 's/├── / * /g' | 
  sed -E 's/│   /   /g' | 
  sed -E 's/└── / * /g' | 
  sed -E 's/    /   /g' |
  # Convert filenames to markdown links but keep only the filename in the link text
  awk '{
    if (NR > 1) {  # Skip the first line which is just "."
      line=$0;
      # Extract the path and create a markdown link
      path=line;
      gsub(/^[ ]*\* /, "", path);  # Remove the bullet and spaces
      
      # Check if it is a directory (ends with a directory name)
      if (path ~ /\/$/) {
        # Remove the trailing slash for display
        display_path=path;
        gsub(/\/$/, "", display_path);
        
        # Create the link
        replacement=" * [" display_path "](./" path ")";
        # Remove the trailing slash in the link URL
        gsub(/\)\/\)/, "))", replacement);
        
        # Replace the original line with the link
        sub(/^[ ]*\* [^ ]+/, replacement, line);
      } else {
        # Get just the filename for display
        split(path, parts, "/");
        filename=parts[length(parts)];
        
        # Create the link
        replacement=" * [" filename "](./" path ")";
        
        # Replace the original line with the link
        sub(/^[ ]*\* [^ ]+/, replacement, line);
      }
      print line;
    } else {
      print $0;  # Print the first line unchanged
    }
  }'
)

# For each file specified in the config
for file_name in $file_names; do
  if [ ! -f "$file_name" ]; then
    echo "File $file_name not found, skipping."
    continue
  fi
  
  # Create the final markdown tree block
  final_tree="## ${chapter}\n\`\`\`\n${formatted_tree}\n\`\`\`"
  
  # Update the README.md file
  if grep -q "^## ${chapter}" "$file_name"; then
    # Find the line number of the Tree section
    start_line=$(grep -n "^## ${chapter}" "$file_name" | cut -d':' -f1)
    
    # Find the line number of the next section or EOF
    next_section=$(tail -n +$((start_line+1)) "$file_name" | grep -n "^##" | head -1)
    if [ -z "$next_section" ]; then
      # If no next section, use the end of file
      end_line=$(wc -l < "$file_name")
    else
      # Extract just the line number
      next_section_line=$(echo "$next_section" | cut -d':' -f1)
      # Adjust to be relative to the whole file
      end_line=$((start_line + next_section_line))
    fi
    
    # Create a temporary file with content before the Tree section
    head -n $start_line "$file_name" > temp_before.md
    # Remove the actual "## Tree" line
    sed -i '$ d' temp_before.md
    
    # Create a temporary file with content after the Tree section
    if [ $end_line -lt $(wc -l < "$file_name") ]; then
      tail -n +$end_line "$file_name" > temp_after.md
    else
      # Create an empty file if there's nothing after
      touch temp_after.md
    fi
    
    # Combine everything together
    {
      cat temp_before.md
      echo -e "\n${final_tree}"
      cat temp_after.md
    } > "$file_name"
    
    # Clean up temporary files
    rm temp_before.md temp_after.md
  else
    # If the section doesn't exist, add it at the end
    echo -e "\n${final_tree}" >> "$file_name"
  fi
done
