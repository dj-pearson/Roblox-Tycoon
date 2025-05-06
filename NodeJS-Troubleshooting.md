# Node.js Environment Troubleshooting

If you encounter issues with Node.js or npm not being recognized, there might be issues with your environment variables. This guide will help you troubleshoot and fix these issues.

## Common Issues

### 1. "Node is not recognized as an internal or external command"

This error occurs when your system cannot find the Node.js executable in your PATH.

**Solution:**

1. **Use the provided batch files**:
   - `run-npm.bat` - For running npm commands
   - `run-argon-sync.bat` - For syncing with Argon
   - `Argon-Setup.bat` - For complete setup and synchronization

2. **Update your PATH manually**:
   1. Open the Start menu and search for "Environment Variables"
   2. Click "Edit the system environment variables"
   3. Click the "Environment Variables" button
   4. Under "System variables", find the "Path" variable and click "Edit"
   5. Check if `C:\Program Files\nodejs\` is present
   6. If not, click "New" and add it
   7. Make sure there are no duplicate entries
   8. Click "OK" on all dialogs to save changes

### 2. npm commands fail

If npm commands fail even though node is recognized, this could be due to npm not being in your PATH.

**Solution:**
- Use `run-npm.bat` for all npm commands:
  ```
  run-npm.bat install -g @argon/cli
  ```

### 3. Argon sync issues

If Argon sync isn't working properly, make sure:
1. Argon is installed (`run-npm.bat install -g @argon/cli`)
2. Node.js environment is set up correctly (use `Argon-Setup.bat`)
3. JSON project files are valid (run `powershell -ExecutionPolicy Bypass -File "Clean-JsonFiles.ps1"`)

## Checking Node.js Installation

You can verify your Node.js installation by running:
```
"C:\Program Files\nodejs\node.exe" -v
```

This should display your Node.js version number.

## Checking Environment Variables

Your PATH environment variable should include:
- `C:\Program Files\nodejs\`
- `%USERPROFILE%\AppData\Roaming\npm` (or `C:\Users\yourusername\AppData\Roaming\npm`)

## Additional Resources

If you're still having issues, you may need to:
1. Reinstall Node.js from [https://nodejs.org/](https://nodejs.org/)
2. Ensure you select the option to "Add to PATH" during installation
3. Restart your computer after installation to ensure PATH changes take effect
