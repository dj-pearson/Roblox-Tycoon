# Luau Script Size Analyzer and Optimizer
# This script analyzes large Luau scripts to help identify areas for optimization

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

function Analyze-LuauFile {
    param(
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "Error: File not found at $FilePath" -ForegroundColor Red
        return
    }
    
    $content = Get-Content $FilePath -Raw
    $fileSize = (Get-Item $FilePath).Length / 1KB
    $fileSizeFormatted = [math]::Round($fileSize, 2)
    
    Write-Host "Analyzing: $FilePath" -ForegroundColor Cyan
    Write-Host "Size: $fileSizeFormatted KB" -ForegroundColor $(if ($fileSize -gt 90) { "Yellow" } else { "Green" })
    Write-Host "===================================" -ForegroundColor Cyan
    
    # Count lines by type
    $lines = $content -split "`n"
    $commentLines = 0
    $emptyLines = 0
    $codeLines = 0
    $longLines = 0
    
    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()
        if ($trimmedLine -eq "") {
            $emptyLines++
        }
        elseif ($trimmedLine -match "^--") {
            $commentLines++
        }
        else {
            $codeLines++
        }
        
        if ($line.Length -gt 100) {
            $longLines++
        }
    }
    
    # Calculate stats
    $totalLines = $lines.Count
    $commentPercent = [math]::Round(($commentLines / $totalLines) * 100, 1)
    $emptyPercent = [math]::Round(($emptyLines / $totalLines) * 100, 1)
    $codePercent = [math]::Round(($codeLines / $totalLines) * 100, 1)
    
    # Find large functions
    $functionMatches = [regex]::Matches($content, "(local\s+function\s+\w+|function\s+[\w\.:]+)\s*\([^\)]*\)")
    $functions = @()
    
    foreach ($match in $functionMatches) {
        $functionName = $match.Value
        $startPos = $match.Index
        
        # Find the end of the function
        $remainingContent = $content.Substring($startPos)
        $depth = 0
        $endPos = 0
        $inString = $false
        $stringDelimiter = ""
        
        for ($i = 0; $i -lt $remainingContent.Length; $i++) {
            $char = $remainingContent[$i]
            $nextChar = if ($i -lt $remainingContent.Length - 1) { $remainingContent[$i+1] } else { "" }
            
            # Handle string literals
            if (($char -eq '"' -or $char -eq "'" -or ($char -eq '[' -and $nextChar -eq '[')) -and -not $inString) {
                $inString = $true
                if ($char -eq '[') {
                    $stringDelimiter = "]]"
                    $i++  # Skip the next '['
                } else {
                    $stringDelimiter = $char
                }
            }
            elseif ($inString) {
                if (($stringDelimiter -eq '"' -or $stringDelimiter -eq "'") -and $char -eq $stringDelimiter -and $remainingContent[$i-1] -ne '\') {
                    $inString = $false
                }
                elseif ($stringDelimiter -eq "]]" -and $char -eq ']' -and $nextChar -eq ']') {
                    $inString = $false
                    $i++  # Skip the next ']'
                }
            }
            
            # Only track function depth if not in a string
            if (-not $inString) {
                if ($remainingContent.Substring($i).StartsWith("function")) {
                    $depth++
                }
                elseif ($remainingContent.Substring($i).StartsWith("end")) {
                    $depth--
                    if ($depth -eq 0) {
                        $endPos = $i + 3  # Length of "end"
                        break
                    }
                }
            }
        }
        
        if ($endPos -gt 0) {
            $functionContent = $remainingContent.Substring(0, $endPos)
            $functionLines = ($functionContent -split "`n").Count
            
            # Calculate the function size in bytes
            $functionSize = [System.Text.Encoding]::UTF8.GetByteCount($functionContent) / 1KB
            $functionSizeFormatted = [math]::Round($functionSize, 2)
            
            $functions += [PSCustomObject]@{
                Name = $functionName
                Lines = $functionLines
                Size = $functionSizeFormatted
            }
        }
    }
    
    # Output stats
    Write-Host "BREAKDOWN BY LINE TYPE:" -ForegroundColor Yellow
    Write-Host "  Total Lines: $totalLines" -ForegroundColor White
    Write-Host "  Code Lines: $codeLines ($codePercent%)" -ForegroundColor White
    Write-Host "  Comment Lines: $commentLines ($commentPercent%)" -ForegroundColor White
    Write-Host "  Empty Lines: $emptyLines ($emptyPercent%)" -ForegroundColor White
    Write-Host "  Long Lines (>100 chars): $longLines" -ForegroundColor White
    
    Write-Host ""
    Write-Host "LARGE FUNCTIONS:" -ForegroundColor Yellow
    $largeFunctions = $functions | Where-Object { $_.Size -gt 5 } | Sort-Object Size -Descending
    
    if ($largeFunctions.Count -gt 0) {
        $largeFunctions | Format-Table -Property @{
            Label = "Function"; 
            Expression = { $_.Name }
        }, @{
            Label = "Lines"; 
            Expression = { $_.Lines }
        }, @{
            Label = "Size (KB)"; 
            Expression = { $_.Size }
        } -AutoSize
    } else {
        Write-Host "  No large functions found (>5KB)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "OPTIMIZATION SUGGESTIONS:" -ForegroundColor Yellow
    
    # Suggestions based on analysis
    if ($fileSize -gt 90) {
        Write-Host "⚠️ This file is approaching Roblox's 100KB limit ($fileSizeFormatted KB)" -ForegroundColor Red
        
        if ($largeFunctions.Count -gt 0) {
            Write-Host "✓ Consider splitting the following large functions into separate modules:" -ForegroundColor Yellow
            foreach ($fn in $largeFunctions | Where-Object { $_.Size -gt 10 }) {
                Write-Host "  - $($fn.Name): $($fn.Size) KB" -ForegroundColor Yellow
            }
        }
        
        if ($commentPercent -gt 15) {
            Write-Host "✓ The file has a high percentage of comments ($commentPercent%). Consider reducing non-essential comments." -ForegroundColor Yellow
        }
        
        if ($emptyPercent -gt 10) {
            Write-Host "✓ The file has a high percentage of empty lines ($emptyPercent%). Consider reducing unnecessary whitespace." -ForegroundColor Yellow
        }
        
        if ($longLines -gt $totalLines * 0.1) {
            Write-Host "✓ The file has many long lines. Consider refactoring complex expressions." -ForegroundColor Yellow
        }
    } else {
        Write-Host "✓ File size is within acceptable limits." -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "FILE SPLITTING RECOMMENDATION:" -ForegroundColor Yellow
    
    if ($fileSize -gt 90) {
        Write-Host "This file should be split into multiple modules to stay under 100KB." -ForegroundColor Yellow
        Write-Host "Suggested approach:" -ForegroundColor White
        Write-Host "1. Move large functions to separate modules:" -ForegroundColor White
        
        $totalSize = 0
        $moduleCount = 1
        $currentModule = [PSCustomObject]@{
            Name = "Module$moduleCount"
            Functions = @()
            Size = 0
        }
        $modules = @($currentModule)
        
        foreach ($fn in $largeFunctions) {
            if ($currentModule.Size + $fn.Size > 90) {
                $moduleCount++
                $currentModule = [PSCustomObject]@{
                    Name = "Module$moduleCount"
                    Functions = @($fn.Name)
                    Size = $fn.Size
                }
                $modules += $currentModule
            } else {
                $currentModule.Functions += $fn.Name
                $currentModule.Size += $fn.Size
            }
        }
        
        foreach ($module in $modules) {
            Write-Host "  - $($module.Name) (~ $([math]::Round($module.Size, 2)) KB)" -ForegroundColor White
            foreach ($fnName in $module.Functions) {
                Write-Host "    * $fnName" -ForegroundColor Gray
            }
        }
        
        Write-Host "2. Create a main module that requires and exposes these modules" -ForegroundColor White
    } else {
        Write-Host "✓ File splitting not necessary at this time." -ForegroundColor Green
    }
}

# Execute the analysis
Analyze-LuauFile -FilePath $FilePath

Read-Host "`nPress Enter to exit..."
