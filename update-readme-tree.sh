#!/bin/bash

# Read configuration from readmetreerc.yml
if [ -f readmetreerc.yml ]; then
  file_names=$(grep -A5 "fileNames:" readmetreerc.yml | grep -v "fileNames:" | sed 's/^[ \t]*-[ \t]*//' | tr -d ' ')
  chapter=$(grep "chapter:" readmetreerc.yml | cut -d':' -f2 | tr -d ' ')
else
  file_names="README.md"
  chapter="Tree"
fi

# Generate the basic tree structure (without including hidden files by default)
tree_output=$(tree -I ".git|node_modules|.github" --noreport --charset ascii .)

# Format the file_names variable
file_names=$(echo "$file_names" | tr ',' ' ')

# Update each file specified in the config
for file_name in $file_names; do
  if [ ! -f "$file_name" ]; then
    echo "File $file_name not found, skipping."
    continue
  fi
  
  # Create the final markdown tree block
  final_tree="## ${chapter}\n\`\`\`\n${tree_output}\n\`\`\`"
  
  # Update the file with the new tree structure
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
      end_line=$((start_line + next_section_line - 1))
    fi
    
    # Create a temporary file with content before the Tree section
    head -n $((start_line-1)) "$file_name" > temp_before.md
    
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
      echo -e "\n${final_tree}\n"
      cat temp_after.md
    } > "$file_name"
    
    # Clean up temporary files
    rm temp_before.md temp_after.md
  else
    # If the section doesn't exist, add it at the end
    echo -e "\n${final_tree}" >> "$file_name"
  fi
done
