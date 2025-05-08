# Rojo Setup and Usage Guide

This guide provides instructions for using Rojo with your Roblox project.

## Quick Start

1. **Start Rojo Server**:
   ```powershell
   # Option 1: Use the convenience script
   .\Start-Rojo.ps1
   
   # Option 2: Direct command
   rojo serve
   ```

2. **Connect to Rojo in Roblox Studio**:
   - Open Roblox Studio
   - Go to the Plugins tab
   - Click on the Rojo plugin (NOT Argon)
   - Connect to the URL shown in the terminal (typically http://localhost:34872)

## Important Notes

1. **Do not run Rojo and Argon simultaneously**:
   - These are different synchronization tools
   - Choose either Rojo or Argon for your development session
   - The Start-Rojo.ps1 script automatically stops any running Argon instances

2. **JSON Requirements**:
   - JSON files must not contain comments (// or /* */)
   - Make sure default.project.json is properly formatted
   - The Start-Rojo.ps1 script automatically removes comments from JSON files

3. **Connection Issues**:
   - If you see a 404 error in Roblox Studio when trying to connect to Rojo:
     - Make sure Rojo is actually running (check the terminal)
     - Ensure you're using the correct port number shown in the terminal
     - Try restarting both Rojo and Roblox Studio

## Common Commands

```powershell
# Start Rojo server
rojo serve

# Build a model file (.rbxlx or .rbxmx)
rojo build -o MyModel.rbxmx

# Update your aftman tools
aftman update
```

## Switching Between Rojo and Argon

If you need to switch between Rojo and Argon:

1. Stop the currently running tool (Rojo or Argon)
2. Start the other tool using its start script:
   - `.\Start-Rojo.ps1` for Rojo
   - `.\Start-Clean-Argon.ps1` for Argon

Created on May 7, 2025
