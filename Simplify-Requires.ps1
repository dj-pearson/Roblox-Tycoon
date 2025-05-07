# Simplify-Requires.ps1
# This script simplifies all require statements to use direct paths without FindFirstChild

$serverFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.luau" -Recurse

foreach ($file in $serverFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # Replace script.Parent:FindFirstChild("ModuleName") with script.Parent.ModuleName
    $newContent = $content -replace 'script\.Parent:FindFirstChild\("(\w+)"\)', 'script.Parent.$1'
    
    # Replace script:FindFirstChild("ModuleName") with script.ModuleName
    $newContent = $newContent -replace 'script:FindFirstChild\("(\w+)"\)', 'script.$1'
    
    if ($newContent -ne $content) {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
        Write-Host "Updated: $($file.Name)"
    }
}

Write-Host "All files processed."
