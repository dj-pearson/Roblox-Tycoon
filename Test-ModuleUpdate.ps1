# Test-ModuleUpdate.ps1
# Diagnostic script to test the module update process

$pluginFolder = Join-Path $PSScriptRoot "DataStore Plugin\src"
$testFile = Join-Path $pluginFolder "DataStoreManager.luau"

Write-Host "Testing module update process..." -ForegroundColor Cyan
Write-Host "Plugin folder: $pluginFolder" -ForegroundColor Gray
Write-Host "Test file: $testFile" -ForegroundColor Gray

if (-not (Test-Path $testFile)) {
    Write-Host "ERROR: Test file not found: $testFile" -ForegroundColor Red
    exit 1
}

# Read the file content
$content = Get-Content -Path $testFile -Raw
Write-Host "Original content length: $($content.Length) bytes" -ForegroundColor Gray

# Print first few lines
$firstLines = $content -split "`n" | Select-Object -First 5
Write-Host "First few lines:" -ForegroundColor Gray
$firstLines | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }

# Test the regex match for comments
if ($content -match "^(--.+\r?\n)+") {
    $commentBlock = $Matches[0]
    Write-Host "Comment block found with length: $($commentBlock.Length) bytes" -ForegroundColor Green
    Write-Host "Comment block content:" -ForegroundColor Gray
    Write-Host $commentBlock -ForegroundColor DarkGray
} else {
    Write-Host "No comment block found at the beginning of the file" -ForegroundColor Yellow
}

# Test the service detection
$codeAfterComments = $content
if ($content -match "^(--.+\r?\n)+") {
    $commentBlock = $Matches[0]
    $codeAfterComments = $content.Substring($commentBlock.Length)
}

if ($codeAfterComments -match "^(local [A-Za-z]+ = game:GetService\([^\)]+\)\r?\n)+") {
    $serviceBlock = $Matches[0]
    Write-Host "Service definitions found:" -ForegroundColor Green
    Write-Host $serviceBlock -ForegroundColor DarkGray
} else {
    Write-Host "No service definitions found at the beginning of the file (after comments)" -ForegroundColor Yellow
}

# Test the require replacement
$testRequirePattern = "require\(script\.Parent\.([A-Za-z0-9_]+)\)"
$requireMatches = [regex]::Matches($content, $testRequirePattern)
if ($requireMatches.Count -gt 0) {
    Write-Host "Found $($requireMatches.Count) require statements to replace:" -ForegroundColor Green
    foreach ($match in $requireMatches) {
        Write-Host "  $($match.Value)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "No require statements found matching the pattern: $testRequirePattern" -ForegroundColor Yellow
}

Write-Host "`nTest complete!" -ForegroundColor Green
