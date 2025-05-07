param (
    [string]$directory = ".\DataStore Plugin"
)

# Get all Lua and Luau files in the directory
$files = Get-ChildItem -Path $directory -Recurse -Include "*.lua", "*.luau"

foreach ($file in $files) {
    Write-Host "Processing $($file.FullName)"
    
    # Read the file content as bytes
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    
    # Check if the file starts with a BOM (U+FEFF in UTF-8 is EF BB BF)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Host "  Found BOM, removing..."
        
        # Create a new array without the BOM
        $newBytes = $bytes[3..$bytes.Length]
        
        # Write the content back without the BOM
        [System.IO.File]::WriteAllBytes($file.FullName, $newBytes)
        
        Write-Host "  BOM removed successfully"
    }
    else {
        Write-Host "  No BOM found, skipping"
    }
}

Write-Host "All files processed"
