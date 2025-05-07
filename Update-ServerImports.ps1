# Update-ServerImports.ps1
# This script updates all server scripts to use FindFirstChild when importing modules

$serverFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.server.luau" -Recurse

$updatedCount = 0

foreach ($file in $serverFiles) {
    $content = Get-Content -Path $file.FullName -Raw

    # Pattern to match standard require statements that don't use FindFirstChild
    $pattern = '(local\s+(\w+)\s+=\s+require\(script\.Parent\.)(\w+)(\))'
    
    # The replacement pattern uses FindFirstChild
    $replacement = '$1FindFirstChild("$3")$4'
    
    # Apply the replacement if the pattern is found
    if ($content -match $pattern) {
        $newContent = $content -replace $pattern, $replacement
        if ($newContent -ne $content) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            Write-Host "Updated imports in $($file.Name)" -ForegroundColor Green
            $updatedCount++
        }
    }
}

Write-Host "Updated $updatedCount server files to use FindFirstChild." -ForegroundColor Cyan
