# Asset Validator Module Documentation

## Overview

The AssetValidator module provides robust asset validation and loading utilities to ensure game assets like images, meshes, sounds, and UI elements are properly loaded before use. This helps prevent visual glitches, broken UIs, and other asset-related errors.

## Key Features

- **Asset Validation**: Verify assets are available and properly loadable
- **Asset Preloading**: Preload commonly used assets to improve performance
- **Error Handling**: Comprehensive error handling for asset loading failures
- **Fallback Assets**: Automatic fallback to default assets when originals fail to load
- **Content Provider Integration**: Uses Roblox's ContentProvider for efficient loading

## API Reference

### Core Validation Functions

```lua
-- Validate a single asset (returns boolean success)
AssetValidator.validateAsset(asset, options)

-- Validate multiple assets (returns boolean success and results table)
AssetValidator.validateAssets(assets, options)

-- Preload assets (alias for validateAssets with preload focus)
AssetValidator.preloadAssets(assets, options)
```

### Asset Information

```lua
-- Get the type of an asset (IMAGE, MESH, SOUND, etc.)
AssetValidator.getAssetType(asset)

-- Get the ID of an asset from an instance
AssetValidator.getAssetId(asset)

-- Check if an asset has been validated
AssetValidator.isAssetValid(assetId)

-- Get a fallback asset for a specific type
AssetValidator.getFallbackAsset(assetType)
```

### Status Information

```lua
-- Get all validated assets
AssetValidator.getValidatedAssets()

-- Get all assets that failed validation
AssetValidator.getFailedAssets()

-- Clear the failed assets cache
AssetValidator.clearCache()
```

## Usage Examples

### Basic Asset Validation

```lua
-- Validate a single UI image
local imageValid = AssetValidator.validateAsset(myImageLabel)

if not imageValid then
    -- Use a fallback image
    myImageLabel.Image = AssetValidator.getFallbackAsset(AssetValidator.assetTypes.IMAGE)
end
```

### Batch Preloading

```lua
-- Preload all UI images in a screen
local images = {}
for _, item in pairs(myScreen:GetDescendants()) do
    if item:IsA("ImageLabel") or item:IsA("ImageButton") then
        table.insert(images, item)
    end
end

-- Preload all images without waiting (suitable for UI workflows)
AssetValidator.preloadAssets(images, {
    noWait = true,
    source = "MyUIScreen"
})
```

### Sound Validation

```lua
-- Validate a sound before playing
if AssetValidator.validateAsset(mySound) then
    mySound:Play()
else
    -- Handle failure
    warn("Failed to load sound:", mySound.SoundId)
end
```

## Integration with Error Handling

The AssetValidator automatically integrates with the ErrorHandlingUtility if available, providing detailed error reporting and logging for asset loading failures.

## Performance Considerations

- Use `noWait = true` for UI asset validation to avoid blocking the main thread
- Preload common assets during game startup or loading screens
- Clear the failed assets cache periodically to retry previously failed assets

## Best Practices

1. Always validate assets before using them, especially for UI elements
2. Provide fallback assets for critical visual elements
3. Use preloading for commonly accessed assets
4. Handle validation failures gracefully with appropriate fallbacks
5. Use source parameters to aid in debugging asset failures
