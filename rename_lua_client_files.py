import os
import sys

def rename_lua_files(root_dir):
    """
    Rename all .lua and .luau files in the given directory and subdirectories
    to follow the [name].client.luau pattern.
    """
    count = 0
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(('.lua', '.luau')) and '.client.' not in filename:
                old_path = os.path.join(dirpath, filename)
                base_name = os.path.splitext(filename)[0]
                new_name = f"{base_name}.client.luau"
                new_path = os.path.join(dirpath, new_name)
                
                print(f"Renaming {old_path} to {new_path}")
                try:
                    os.rename(old_path, new_path)
                    count += 1
                except Exception as e:
                    print(f"Error renaming {filename}: {e}")
    
    print(f"\nRenamed {count} files to follow the [name].client.luau pattern.")

if __name__ == "__main__":
    client_directory = r"c:\Users\pears\OneDrive\Documents\Roblox Scripts\src\client"
    if os.path.exists(client_directory):
        print(f"Starting to rename Lua files in {client_directory}")
        rename_lua_files(client_directory)
    else:
        print(f"Directory not found: {client_directory}")