# Fix-StackOverflow.ps1
# This script attempts to diagnose and fix common causes of stack overflow errors in Argon and Luau scripts

Write-Host "Checking for recursion issues in Luau scripts..." -ForegroundColor Cyan

# Directories to check for recursive require patterns
$dirsToCheck = @(
    "src/shared",
    "src/server",
    "src/client"
)

# Patterns that might indicate recursion issues
$recursionPatterns = @(
    "(?smi)local\s+[a-zA-Z0-9_]+\s*=\s*require\(.*?\)\s*.*?\1\s*=\s*require",  # Same module required twice
    "(?smi)local\s+[a-zA-Z0-9_]+\s*=\s*require\(.*?\)\s*.*?return\s+[a-zA-Z0-9_]+",  # Circular dependency pattern
    "(?smi)function\s+[a-zA-Z0-9_]+\([^)]*\).*?\1\([^)]*\)"  # Potential recursive function call
)

$problemsFound = $false

foreach ($dir in $dirsToCheck) {
    $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $dir
    
    if (Test-Path $fullPath) {
        Write-Host "Checking directory: $fullPath" -ForegroundColor Yellow
        
        # Get all Luau/Lua files
        $luaFiles = Get-ChildItem -Path $fullPath -Recurse -File -Include "*.lua", "*.luau"
        
        foreach ($file in $luaFiles) {
            Write-Host "  Analyzing $($file.Name)..." -ForegroundColor Gray
            
            $content = Get-Content -Path $file.FullName -Raw
            
            foreach ($pattern in $recursionPatterns) {
                if ($content -match $pattern) {
                    Write-Host "    Potential recursion issue found in: $($file.FullName)" -ForegroundColor Red
                    Write-Host "    Pattern matched: $pattern" -ForegroundColor Red
                    $problemsFound = $true
                }
            }
        }
    } else {
        Write-Host "Directory not found: $fullPath" -ForegroundColor Yellow
    }
}

# Check for issues in the Node.js launch config
Write-Host "`nChecking Node.js configuration..." -ForegroundColor Cyan

try {
    # Get Node.js version and memory limit
    $nodeVersion = node --version
    Write-Host "Node.js version: $nodeVersion" -ForegroundColor Green
    
    # Recommend increasing stack size if using an older version of Node.js
    if ($nodeVersion -match "^v8\.|^v10\.") {
        Write-Host "You're using an older version of Node.js which might have lower default stack sizes." -ForegroundColor Yellow
        Write-Host "Consider updating to a newer version of Node.js." -ForegroundColor Yellow
    }
    
    Write-Host "Testing Node.js memory allocation..." -ForegroundColor Yellow
    # Run a simple test to check memory allocation
    $memTest = node --eval "console.log('Max memory:', require('v8').getHeapStatistics().heap_size_limit / (1024*1024), 'MB');"
    Write-Host $memTest -ForegroundColor Gray
    
} catch {
    Write-Host "Error checking Node.js configuration: $_" -ForegroundColor Red
}

# Recommendations
Write-Host "`nRecommendations to fix stack overflow issues:" -ForegroundColor Cyan

if ($problemsFound) {
    Write-Host "1. Review the files mentioned above for circular dependencies." -ForegroundColor Yellow
    Write-Host "2. Break circular dependencies by restructuring your code or using dependency injection." -ForegroundColor Yellow
    Write-Host "3. Check for infinite recursive function calls." -ForegroundColor Yellow
} else {
    Write-Host "No obvious recursion issues found in the code." -ForegroundColor Green
}

Write-Host "4. Try running Node.js with increased stack size:" -ForegroundColor Yellow
Write-Host "   node --stack-size=4096 ..." -ForegroundColor Gray

Write-Host "5. If using the Argon tool, edit your aftman.toml to ensure you're using the latest version." -ForegroundColor Yellow
Write-Host "6. Check for large JSON files or deep object structures that might cause stack issues during serialization." -ForegroundColor Yellow

Write-Host "`nScript completed. Use the recommendations above to address any stack overflow issues." -ForegroundColor Cyan
