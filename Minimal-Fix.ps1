# Minimal-Fix.ps1
# The most minimal approach possible

# Create a simple project.json file without $ characters first as a test
$simpleJson = @'
{
  "name": "RobloxTest",
  "tree": {
    "className": "DataModel",
    "ReplicatedStorage": {
      "shared": {
        "path": "src/shared"
      }
    }
  }
}
'@

# Write to file with UTF-8 encoding without BOM
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$PSScriptRoot\test.project.json", $simpleJson, $utf8NoBomEncoding)

Write-Host "Created test.project.json - please try running: argon serve --project test.project.json" -ForegroundColor Green
