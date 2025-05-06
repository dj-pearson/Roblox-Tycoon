# Simplified Argon JSON Configuration

## What Changed

We've simplified the project JSON files to make them more reliable with Argon:

1. **Removed BOM (Byte Order Mark)** characters from JSON files that were causing parsing errors
2. **Removed comments** from JSON files
3. **Simplified structure** by removing unnecessary options:
   - Removed `$ignoreUnknownInstances` and `$ignoreFiles` directives
   - Kept only the essential structure required for syncing

## Files Modified

- `DataStore-plugin.project.json` - Simplified plugin configuration
- `default.project.json` - Simplified project structure
- `main.project.json` - Simplified main project with plugin

## How to Fix JSON Parsing Errors

If you encounter JSON parsing errors when using Argon, you can:

1. Run the new `Fix-JsonFiles-NoBOM.ps1` script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File Fix-JsonFiles-NoBOM.ps1
   ```

2. Try the simplified sync batch file:
   ```
   Simple-Plugin-Sync.bat
   ```

## JSON Structure Best Practices

For Argon compatibility:

1. Use UTF-8 encoding **without** BOM
2. Don't include comments in JSON files
3. Keep the structure as simple as possible
4. Use valid JSON format (double quotes, proper commas, etc.)

## Plugin Structure

The simplified plugin structure is:

```json
{
  "name": "DataStore Manager Pro",
  "tree": {
    "$className": "Plugin",
    "$properties": {
      "RunContext": "Server"
    },
    "$path": "DataStore Plugin"
  }
}
```

This maps directly to the DataStore Plugin folder with minimal configuration.
