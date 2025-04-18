import os
import sys

def scan_file_for_non_utf8(file_path):
    """Scan a single file for non-UTF-8 characters."""
    try:
        with open(file_path, 'rb') as file:
            content = file.read()
            try:
                content.decode('utf-8')
                return None
            except UnicodeDecodeError as e:
                # Find the line where the error occurred
                lines = content.split(b'\n')
                char_count = 0
                line_number = 0
                for i, line in enumerate(lines):
                    if char_count + len(line) >= e.start:
                        line_number = i + 1
                        position_in_line = e.start - char_count
                        break
                    char_count += len(line) + 1  # +1 for the newline character
                
                # Get the problematic byte and surrounding context
                bad_byte_index = e.start
                context_start = max(0, bad_byte_index - 10)
                context_end = min(len(content), bad_byte_index + 10)
                context = content[context_start:context_end]
                
                return {
                    'file': file_path,
                    'line': line_number,
                    'position': position_in_line,
                    'error': str(e),
                    'hex_values': [hex(b) for b in content[bad_byte_index:bad_byte_index+1]],
                    'context_hex': [hex(b) for b in context]
                }
    except Exception as e:
        return {
            'file': file_path,
            'error': f"Error opening file: {str(e)}"
        }

def scan_directory_for_non_utf8(directory):
    """Recursively scan a directory for files with non-UTF-8 characters."""
    issues = []
    
    for root, _, files in os.walk(directory):
        for file in files:
            # Only check code files - add or remove extensions as needed
            code_extensions = ['.lua', '.luau', '.py', '.js', '.ts', '.cpp', '.h', '.cs', '.java', '.php', '.html', '.css', '.xml', '.json']
            if any(file.endswith(ext) for ext in code_extensions):
                file_path = os.path.join(root, file)
                result = scan_file_for_non_utf8(file_path)
                if result:
                    issues.append(result)
    
    return issues

def main():
    if len(sys.argv) < 2:
        print("Usage: python script.py <directory_path>")
        sys.exit(1)
    
    directory = sys.argv[1]
    if not os.path.isdir(directory):
        print(f"Error: {directory} is not a valid directory")
        sys.exit(1)
    
    print(f"Scanning directory: {directory}")
    issues = scan_directory_for_non_utf8(directory)
    
    if not issues:
        print("No UTF-8 encoding issues found in any files.")
    else:
        print(f"Found {len(issues)} files with UTF-8 encoding issues:")
        for issue in issues:
            print("\n" + "="*50)
            print(f"File: {issue['file']}")
            if 'line' in issue:
                print(f"Line: {issue['line']}, Position: {issue['position']}")
                print(f"Error: {issue['error']}")
                print(f"Problematic byte (hex): {issue['hex_values']}")
                print(f"Context (hex): {issue['context_hex']}")
            else:
                print(f"Error: {issue['error']}")

if __name__ == "__main__":
    main()