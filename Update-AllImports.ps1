# Update-AllImports.ps1
# This script updates require statements in all Lua files to use FindFirstChild

$luaFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.luau" -Recurse

foreach ($file in $luaFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $updated = $false
    
    # Replace standard dot notation requires with FindFirstChild
    $pattern = 'require\(script\.Parent\.([^\.:\)]+)\)'
    if ($content -match $pattern) {
        $newContent = $content -replace $pattern, 'require(script.Parent:FindFirstChild("$1"))'
        if ($newContent -ne $content) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            Write-Host "Updated imports in $($file.Name)" -ForegroundColor Green
            $updated = $true
        }
    }
    
    if (-not $updated) {
        Write-Host "No updates needed for $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "All files processed." -ForegroundColor Cyan
