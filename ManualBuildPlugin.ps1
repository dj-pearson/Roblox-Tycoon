# ManualBuildPlugin.ps1
# This script builds the DataStore Plugin without relying on Rojo

Write-Host "Manually building DataStore Plugin..." -ForegroundColor Cyan

# Configuration
$sourceFolder = "DataStore Plugin"
$outputFile = "DataStorePlugin_New.rbxmx"
$pluginsFolder = "$env:LOCALAPPDATA\Roblox\Plugins"

# Create a timestamp in the plugin
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$timestampFile = "$sourceFolder\src\BuildTimestamp.luau"
Set-Content -Path $timestampFile -Value "--luau`n-- Build timestamp: $timestamp`n`nreturn '$timestamp'"

Write-Host "Added build timestamp: $timestamp" -ForegroundColor Yellow

# Use PowerShell to package the plugin
Write-Host "Packaging plugin files..." -ForegroundColor Yellow

# Function to convert a directory to XML structure
function ConvertTo-PluginXml {
    param (
        [string]$directory,
        [string]$name = (Split-Path $directory -Leaf),
        [int]$indent = 0
    )
    
    $indentStr = " " * $indent
    $xml = "$indentStr<Item class=`"Folder`" referent=`"$([guid]::NewGuid())`">`n"
    $xml += "$indentStr  <Properties>`n"
    $xml += "$indentStr    <string name=`"Name`">$name</string>`n"
    $xml += "$indentStr  </Properties>`n"
    $xml += "$indentStr  <Item class=`"Folder`" referent=`"$([guid]::NewGuid())`">`n"
    $xml += "$indentStr    <Properties>`n"
    $xml += "$indentStr      <string name=`"Name`">src</string>`n"
    $xml += "$indentStr    </Properties>`n"
    
    # Add source files
    $files = Get-ChildItem -Path "$directory\src" -File -Filter "*.luau" -Recurse
    foreach ($file in $files) {
        $fileContent = Get-Content -Path $file.FullName -Raw
        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        
        $xml += "$indentStr    <Item class=`"ModuleScript`" referent=`"$([guid]::NewGuid())`">`n"
        $xml += "$indentStr      <Properties>`n"
        $xml += "$indentStr        <string name=`"Name`">$moduleName</string>`n"
        $xml += "$indentStr        <string name=`"Source`"><![CDATA[$fileContent]]></string>`n"
        $xml += "$indentStr      </Properties>`n"
        $xml += "$indentStr    </Item>`n"
    }
    
    $xml += "$indentStr  </Item>`n"
    $xml += "$indentStr</Item>"
    
    return $xml
}

# Create RBXMX file
$header = @"
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Meta name="ExplicitAutoJoints">true</Meta>
  <External>null</External>
  <External>nil</External>
"@

$footer = @"
</roblox>
"@

$pluginXml = ConvertTo-PluginXml -directory $sourceFolder -name "DataStore Manager Pro"
$fullXml = "$header`n$pluginXml`n$footer"

Set-Content -Path $outputFile -Value $fullXml
Write-Host "Plugin file created: $outputFile" -ForegroundColor Green

# Copy to Roblox Plugins folder if it exists
if (Test-Path $pluginsFolder) {
    Copy-Item -Path $outputFile -Destination "$pluginsFolder\DataStorePlugin.rbxmx" -Force
    Write-Host "Plugin copied to Roblox Plugins folder: $pluginsFolder\DataStorePlugin.rbxmx" -ForegroundColor Green
} else {
    Write-Host "Roblox Plugins folder not found at: $pluginsFolder" -ForegroundColor Yellow
    Write-Host "You may need to manually copy the plugin file to your Roblox Plugins folder." -ForegroundColor Yellow
}

Write-Host "Manual build complete!" -ForegroundColor Green
