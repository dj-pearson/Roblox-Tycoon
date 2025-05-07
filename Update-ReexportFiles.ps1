# Update-ReexportFiles.ps1
# This script updates all re-export files to properly reference the server scripts in Roblox

$reexportFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.luau" -Recurse | Where-Object { 
    $_.Name -notlike "*.server.luau" -and $_.Name -notlike "*.client.luau"
}

$template = @"
--luau
-- DataStore Plugin/{0}.luau
-- This is a re-export file that properly references the server script in Roblox

-- In Roblox, the server script will be named "{0}" 
-- without the .server extension
return require(script.Parent:FindFirstChild("{0}"))
"@

foreach ($file in $reexportFiles) {
    # Check if this is a re-export file (contains return require(script.server))
    $content = Get-Content -Path $file.FullName -Raw
    if ($content -match "return require\(script\.server\)") {
        $moduleName = $file.BaseName
        $newContent = $template -f $moduleName
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
        Write-Host "Updated $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "Re-export files update complete." -ForegroundColor Cyan
