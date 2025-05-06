try {
     = [ScriptBlock]::Create((Get-Content -Path "C:\Users\dpearson\OneDrive\Documents\RobloxProject\Clean-JsonFiles.ps1" -Raw))
    Write-Host "Script syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "Script syntax contains errors:" -ForegroundColor Red
    Write-Host .Exception.Message -ForegroundColor Red
}
