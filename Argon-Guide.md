# Argon Setup and Troubleshooting Guide

This guide provides steps for setting up and using Argon for Roblox development in this project.

## Quick Start

1. **Start Argon Server**:
   ```powershell
   cd "c:\Users\pears\OneDrive\Documents\RobloxProject"
   argon serve
   ```

2. **Connect to Argon in Roblox Studio**:
   - Open Roblox Studio
   - Go to the Plugins tab
   - Click on the Argon plugin
   - Connect to `http://localhost:8000`

## Troubleshooting Steps

If you encounter issues with Argon:

1. **Reset JSON Configuration**:
   ```powershell
   .\Quick-Fix-Default-JSON.ps1
   ```
   This creates a clean default.project.json file with the correct UTF-8 encoding (without BOM)

2. **Complete Reset**:
   ```powershell
   # Run the Argon Reset Instructions script
   . .\Argon-Reset-Instructions.ps1
   
   # Complete repair process
   Repair-ArgonProject -Force
   ```

3. **Manual Start with Fixed Configuration**:
   ```powershell
   # Stop any existing Argon processes
   Stop-Process -Name "argon" -Force -ErrorAction SilentlyContinue
   
   # Create a clean configuration
   .\Quick-Fix-Default-JSON.ps1
   
   # Start Argon
   argon serve
   ```

## Common Issues and Solutions

1. **Stack Overflow Error**:
   - This usually indicates circular references in your project structure
   - Use the Repair-ArgonProject command to fix

2. **JSON Parsing Errors**:
   - Often caused by BOM characters in JSON files
   - Use Quick-Fix-Default-JSON.ps1 to create clean JSON without BOM

3. **Port Already in Use**:
   - If port 8000 is in use, Argon will automatically use port 8001
   - Check the console output for the actual port being used

## Project Structure

The current default.project.json is configured with:

- ReplicatedStorage/shared (from src/shared)
- ServerScriptService/server (from src/server)
- StarterPlayer/StarterPlayerScripts/client (from src/client)

Created on May 7, 2025
