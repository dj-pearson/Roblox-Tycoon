# Project Structure Analysis Scripts

This set of scripts will help you analyze and visualize the current structure of your Roblox project, providing valuable insights for reorganization and reimagining.

## Available Scripts

1. **FolderStructureAnalyzer.server.lua**
   - Analyzes the complete folder structure of your Roblox game
   - Generates a comprehensive report of all game services and their hierarchy
   - Counts scripts, modules, and other objects
   - Outputs both to console and saves in ServerStorage for reference

2. **DataStorePluginAnalyzer.server.lua**
   - Focuses specifically on analyzing the DataStore Plugin structure
   - Identifies modules, dependencies, and potential circular dependencies
   - Helps understand the plugin's organization for potential improvements

3. **ProjectDependenciesVisualizer.server.lua**
   - Creates a visual representation of dependencies between modules
   - Generates a graph in DOT format that can be visualized using online tools
   - Identifies module clusters and categorizes them to help with reorganization

## How to Use These Scripts

1. **Open your Roblox place file** in Roblox Studio
2. **Insert the scripts** into ServerScriptService
3. **Run the game** in Studio (either Play or Run mode)
4. **Check the Output window** for the analysis results
5. **Browse ServerStorage** for saved reports and visualization data

## Visualizing the Dependency Graph

The ProjectDependenciesVisualizer script generates a DOT format graph that you can visualize:

1. Copy the contents of the "ProjectGraph_DOT_..." StringValue in ServerStorage
2. Visit https://dreampuf.github.io/GraphvizOnline/ or any other Graphviz online tool
3. Paste the graph data and render the visualization
4. Use the resulting diagram to understand module relationships

## Using This Information for Project Restructuring

The data from these scripts can help you:

1. **Identify overly complex areas** of your codebase
2. **Find circular dependencies** that should be refactored
3. **Discover logical groupings** of functionality
4. **Plan a cleaner architecture** based on actual usage patterns
5. **Create proper separation of concerns**

## Best Practices for Reorganization

When reimagining your project structure, consider:

1. **Modular architecture** with clear boundaries
2. **Dependency injection** instead of direct references
3. **Service-oriented design** for core functionality
4. **Proper client-server separation**
5. **Consistent naming conventions**
6. **Documentation for complex systems**

By analyzing your current structure, you can make informed decisions about how to reorganize your code for better maintainability and scalability.
