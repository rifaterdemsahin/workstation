import os
import re
import unicodedata
import shutil

def sanitize_filename(filename):
    """
    Sanitize filename to be Obsidian-friendly by:
    1. Removing or replacing restricted characters
    2. Removing emoji and other special characters
    3. Ensuring unique filenames
    4. Limiting filename length
    """
    # Normalize the filename to remove accents and convert to ASCII
    filename = unicodedata.normalize('NFKD', filename).encode('ascii', 'ignore').decode('utf-8')
    
    # Remove or replace restricted characters
    restricted_chars = r'[<>:"/\\|?*\[\]#^]'
    filename = re.sub(restricted_chars, ' ', filename)
    
    # Remove emoji and other special characters
    emoji_pattern = re.compile(
        "["
        u"\U0001F600-\U0001F64F"  # emoticons
        u"\U0001F300-\U0001F5FF"  # symbols & pictographs
        u"\U0001F680-\U0001F6FF"  # transport & map symbols
        u"\U0001F1E0-\U0001F1FF"  # flags (iOS)
        u"\U00002702-\U000027B0"
        u"\U000024C2-\U0001F251"
        "]+", flags=re.UNICODE)
    filename = emoji_pattern.sub(r'', filename)
    
    # Replace multiple spaces with a single space and strip
    filename = re.sub(r'\s+', ' ', filename).strip()
    
    # Truncate filename if too long (max 255 characters)
    filename = filename[:255]
    
    # Ensure filename is not empty
    if not filename:
        filename = 'unnamed_file'
    
    return filename

def rename_files_in_directory(base_path):
    """
    Rename files in the given directory and its subdirectories
    to be Obsidian-friendly
    """
    renamed_files = []
    duplicate_counter = {}

    for root, dirs, files in os.walk(base_path):
        for filename in files:
            # Full original path
            original_path = os.path.join(root, filename)
            
            # Sanitize filename
            sanitized_name = sanitize_filename(filename)
            
            # Handle potential duplicates
            if sanitized_name in duplicate_counter:
                duplicate_counter[sanitized_name] += 1
                base, ext = os.path.splitext(sanitized_name)
                sanitized_name = f"{base}_{duplicate_counter[sanitized_name]}{ext}"
            else:
                duplicate_counter[sanitized_name] = 0
            
            # Full new path
            new_path = os.path.join(root, sanitized_name)
            
            # Rename file if name is different
            if original_path != new_path:
                try:
                    shutil.move(original_path, new_path)
                    renamed_files.append((original_path, new_path))
                except Exception as e:
                    print(f"Error renaming {original_path}: {e}")
    
    return renamed_files

def main():
    # Set the base path for your Obsidian vault
    epo_path = r'C:\projects\secondbrain'
    
    # Perform renaming
    renamed_files = rename_files_in_directory(epo_path)
    
    # Print report
    print("File Renaming Report:")
    print("-" * 50)
    print(f"Total files renamed: {len(renamed_files)}")
    print("\nRenamed Files:")
    for old, new in renamed_files:
        print(f"Old: {old}")
        print(f"New: {new}")
        print()

if __name__ == "__main__":
    main()
