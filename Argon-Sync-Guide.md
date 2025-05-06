# Argon Synchronization Guide for Roblox Project

This guide explains how to synchronize your Roblox project with Roblox Studio using Argon instead of Rojo.

## Project Files

This project includes multiple project files for different synchronization scenarios:

1. **main.project.json**
   - Main project file that includes all game components **and** the DataStore plugin
   - Use this to sync the entire project at once
   - Contains proper structure with Plugins inside DataModel

2. **DataStore-plugin.project.json**
   - Standalone plugin file
   - Use this to sync only the DataStore plugin
   - Perfect for plugin development/testing without the main game

3. **default.project.json**
   - Original project structure (kept for reference)
   - Not recommended for use with Argon

## Batch Files for Synchronization

Several batch files are provided to facilitate synchronization:

1. **Sync-MainProject.bat**
   - Syncs the entire project using main.project.json
   - Includes game components and plugin
   - Offers watch mode option

2. **Test-PluginSync.bat**
   - Syncs only the DataStore plugin as a standalone plugin
   - Uses DataStore-plugin.project.json

3. **Argon-Setup.bat**
   - Comprehensive utility for environment setup
   - Checks/installs Node.js and Argon
   - Provides options to sync any project file

4. **run-argon-sync.bat**
   - Utility for running Argon with proper Node.js environment
   - Accepts command line parameters for flexibility

## File Size Considerations

Argon has a size limit of approximately 100KB per file. Several strategies are employed to handle large files:

1. **Large Image Files**
   - Images exceeding 100KB are stored in the Backups directory
   - These files are excluded from synchronization using $ignoreFiles
   - Affected files: DataStore-Cover.png, Logo.png, Store Image.png

2. **Exclusion Patterns**
   - The project files use $ignoreFiles to exclude:
     - PNG files (*.png)
     - Backup files (*.backup*)
     - Text files (*.txt)
     - Documentation files (README.md)
     - The .gitignore file

## Troubleshooting

If synchronization fails:

1. **Node.js Environment Issues**
   - Use run-npm.bat for running any npm commands
   - Check NodeJS-Troubleshooting.md for detailed guidance

2. **JSON File Issues**
   - Run Fix-JsonFiles.ps1 to remove comments from JSON files
   - Use Clean-JsonFiles.ps1 to completely recreate JSON files with known good content

3. **Plugin Not Appearing**
   - Verify that init.server.luau is properly structured
   - Check that the asset ID used for the plugin icon is valid
   - Ensure proper RunContext property is set in the plugin project file

## Testing the Plugin

After synchronization:

1. Open Roblox Studio
2. Look for "DataStore Manager Pro" in the Plugins tab
3. Click the plugin button to open the interface
4. Test all functionality to ensure proper operation

## Project Structure Recommendations

- Keep large asset files in a separate Backups directory
- Create separate project files for different synchronization needs
- Use appropriate batch files to simplify the synchronization process
- Follow Argon's requirements for project structure and file sizes
