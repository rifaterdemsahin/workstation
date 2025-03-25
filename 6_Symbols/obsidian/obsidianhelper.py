import os
import re

# Define the repository path
repo_path = 'C:\projects\secondbrain'

# Regular expression to match Obsidian-friendly filenames
# This example allows alphanumeric characters, hyphens, underscores, and periods.
obsidian_friendly_pattern = re.compile(r'^[\w\-. ]+$')

# List to store files that need renaming
files_to_rename = []

# Walk through the repository
for root, dirs, files in os.walk(repo_path):
    for filename in files:
        if not obsidian_friendly_pattern.match(filename):
            # Collect the full path of files that don't match the pattern
            files_to_rename.append(os.path.join(root, filename))

# Output the list of files that need renaming
if files_to_rename:
    print("The following files have names that may not be Obsidian-friendly and may need renaming:")
    for file in files_to_rename:
        print(file)
else:
    print("All files have Obsidian-friendly names.")
