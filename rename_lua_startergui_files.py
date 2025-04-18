import os
import sys

def rename_lua_files(root_dir):
    """
    Rename all .lua and .luau files in the given directory and subdirectories
    to follow the [name].server.luau pattern.
    """
    count = 0
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(('.lua', '.luau')) and '.server.' not in filename:
                old_path = os.path.join(dirpath, filename)
                base_name = os.path.splitext(filename)[0]
                new_name = f"{base_name}.server.luau"
                new_path = os.path.join(dirpath, new_name)
                
                print(f"Renaming {old_path} to {new_path}")
                try:
                    os.rename(old_path, new_path)
                    count += 1
                except Exception as e:
                    print(f"Error renaming {filename}: {e}")
    
    print(f"\nRenamed {count} files to follow the [name].server.luau pattern.")

if __name__ == "__main__":
    startergui_directory = r"c:\Users\pears\OneDrive\Documents\Roblox Scripts\src\StarterGui"
    if os.path.exists(startergui_directory):
        print(f"Starting to rename Lua files in {startergui_directory}")
        rename_lua_files(startergui_directory)
    else:
        print(f"Directory not found: {startergui_directory}")