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

# Default to README.md if no file names specified
if [ -z "$file_names" ]; then
  file_names="README.md"
fi

# Default to "Tree" if no chapter specified
if [ -z "$chapter" ]; then
  chapter="Tree"
fi

# Default to "." if no include directories specified
if [ -z "$include_dirs" ]; then
  include_dirs="."
fi

for file_name in $file_names; do
  if [ ! -f "$file_name" ]; then
    echo "File $file_name not found, skipping."
    continue
  fi
  
  # Generate tree structure for each include directory
  tree_output=""
  for dir in $include_dirs; do
    if [ -d "$dir" ]; then
      dir_tree=$(tree -tf --noreport -I '*~|.git|node_modules' --charset ascii "$dir" | 
                 sed -e 's/| \+/  /g' -e 's/[|`]-\+/ */g' -e 's:\(* \)\(\(.*/\)\([^/]\+\)\):\1[\4](\2):g')
      tree_output="${tree_output}${dir_tree}\n"
    fi
  done
  
  # Format the tree output
  formatted_tree="\`\`\`\n${tree_output}\`\`\`"
  
  # Update the file with the new tree structure
  if grep -q "^## ${chapter}" "$file_name"; then
    # Replace content between this section and the next section
    awk -v chapter="$chapter" -v tree="$formatted_tree" '
    BEGIN {p=1; found=0}
    $0 ~ "^## " chapter {print; p=0; print tree; found=1; next}
    $0 ~ /^##[^#]/ {if (p==0) {p=1}}
    p==1 {print}
    END {if (found==0) {print "## " chapter; print tree}}
    ' "$file_name" > temp.md && mv temp.md "$file_name"
  else
    # If the section doesn't exist, add it at the end
    echo -e "\n## ${chapter}\n${formatted_tree}" >> "$file_name"
  fi
done
