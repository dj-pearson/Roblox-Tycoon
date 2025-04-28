# AssetValidator Module Documentation

## Overview

The `AssetValidator` module provides a robust system for validating and handling assets in the game. It ensures that assets like images, sounds, and animations are valid before attempting to use them, preventing common asset loading failures. The module was created to fix critical "Asset Loading Failures" issues reported in the game.

## Features

- **Asset ID Validation**: Verifies that asset IDs point to valid resources
- **Fallback Mechanisms**: Provides fallback assets when primary assets fail to load
- **Asset Preloading**: Queues assets for preloading to improve performance
- **Client-Side Validation**: Validates assets on the client where possible
- **Server-Side Fallbacks**: Provides consistent behavior on both server and client
- **Custom Fallbacks**: Allows registration of custom fallback assets per type
- **Event System Integration**: Fires events on validation success and failure

## API Reference

### Initialization

#### `AssetValidator.initialize()`
Initializes the AssetValidator module. Sets up the preloading system and registers events.

**Returns:**
- `boolean`: `true` if initialization was successful

**Example:**
```lua
AssetValidator.initialize()
```

### Asset Validation

#### `AssetValidator.validateAssetId(assetId, options)`
Validates an asset ID and returns either the validated ID or a fallback.

**Parameters:**
- `assetId` (number/string): The asset ID or full rbxassetid:// format
- `options` (table, optional): Additional options
  - `assetType` (string): Type of the asset (see `ASSET_TYPES`)
  - `fallback` (string): Custom fallback asset ID
  - `mustValidate` (boolean): Whether validation must be performed

**Returns:**
- `string`: The validated asset ID or fallback ID

**Example:**
```lua
local validatedId = AssetValidator.validateAssetId(12345678, {
    assetType = AssetValidator.ASSET_TYPES.IMAGE,
    fallback = "rbxassetid://00000000"
})
```

#### `AssetValidator.validateImageId(imageId, fallback)`
Convenience method specifically for validating image assets.

**Parameters:**
- `imageId` (number/string): The image asset ID
- `fallback` (string, optional): Custom fallback image ID

**Returns:**
- `string`: The validated image ID or fallback ID

**Example:**
```lua
local validatedImageId = AssetValidator.validateImageId(12345678)
```

#### `AssetValidator.validateSoundId(soundId, fallback)`
Convenience method specifically for validating sound assets.

**Parameters:**
- `soundId` (number/string): The sound asset ID
- `fallback` (string, optional): Custom fallback sound ID

**Returns:**
- `string`: The validated sound ID or fallback ID

**Example:**
```lua
local validatedSoundId = AssetValidator.validateSoundId(12345678)
```

### Asset Creation

#### `AssetValidator.createImageLabel(imageId, properties)`
Creates an ImageLabel with a validated image ID.

**Parameters:**
- `imageId` (number/string): The image asset ID
- `properties` (table, optional): Additional properties for the ImageLabel
  - `fallback` (string): Custom fallback image ID
  - Other standard ImageLabel properties

**Returns:**
- `ImageLabel`: The created ImageLabel instance

**Example:**
```lua
local imageLabel = AssetValidator.createImageLabel(12345678, {
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 200, 0, 200),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Parent = screenGui
})
```

#### `AssetValidator.createSound(soundId, properties)`
Creates a Sound with a validated sound ID.

**Parameters:**
- `soundId` (number/string): The sound asset ID
- `properties` (table, optional): Additional properties for the Sound
  - `fallback` (string): Custom fallback sound ID
  - Other standard Sound properties

**Returns:**
- `Sound`: The created Sound instance

**Example:**
```lua
local sound = AssetValidator.createSound(12345678, {
    Volume = 0.5,
    Looped = true,
    Parent = workspace
})
```

### Fallback Management

#### `AssetValidator.registerFallback(assetType, fallbackId)`
Registers a custom fallback asset for a specific asset type.

**Parameters:**
- `assetType` (string): The asset type (see `ASSET_TYPES`)
- `fallbackId` (string/number): The fallback asset ID

**Returns:**
- `boolean`: `true` if registration was successful, `false` otherwise

**Example:**
```lua
AssetValidator.registerFallback(
    AssetValidator.ASSET_TYPES.IMAGE,
    "rbxassetid://123456789"
)
```

#### `AssetValidator.getFallback(assetType, customFallback)`
Gets the appropriate fallback asset for a given type.

**Parameters:**
- `assetType` (string): The asset type (see `ASSET_TYPES`)
- `customFallback` (string, optional): A custom fallback to use if provided

**Returns:**
- `string`: The fallback asset ID or nil

**Example:**
```lua
local fallbackImageId = AssetValidator.getFallback(AssetValidator.ASSET_TYPES.IMAGE)
```

### Asset Preloading

#### `AssetValidator.preloadAssets(assets)`
Queues assets for preloading to improve performance.

**Parameters:**
- `assets` (table): Array of assets to preload
  - Each asset can be a string ID or a table with `id` and `type` fields

**Returns:**
- `boolean`: `true` if preloading was queued successfully

**Example:**
```lua
AssetValidator.preloadAssets({
    "rbxassetid://123456789",
    { id = "rbxassetid://987654321", type = AssetValidator.ASSET_TYPES.SOUND }
})
```

### Cache Management

#### `AssetValidator.clearCache()`
Clears the validation cache, forcing re-validation of assets.

**Example:**
```lua
AssetValidator.clearCache()
```

### Utility Functions

#### `AssetValidator.getAssetTypeByExtension(extension)`
Determines the asset type based on a file extension.

**Parameters:**
- `extension` (string): The file extension (e.g., "png", "mp3")

**Returns:**
- `string`: The corresponding asset type

**Example:**
```lua
local assetType = AssetValidator.getAssetTypeByExtension("png")
-- Returns AssetValidator.ASSET_TYPES.IMAGE
```

## Constants

### Asset Types

`AssetValidator.ASSET_TYPES` provides constants for different types of assets:

- `IMAGE`: For images (e.g., textures, icons)
- `SOUND`: For audio files
- `ANIMATION`: For animations
- `MESH`: For mesh parts
- `TEXTURE`: For textures
- `FONT`: For fonts
- `PACKAGE`: For packages
- `PLUGIN`: For plugins
- `UNKNOWN`: Default for unspecified types

**Example:**
```lua
local imageType = AssetValidator.ASSET_TYPES.IMAGE
```

## Events

When integrated with EventBridge, the AssetValidator fires the following events:

- **AssetValidator_AssetValidated**: Fired when an asset is successfully validated
- **AssetValidator_AssetFailed**: Fired when an asset fails validation
- **AssetValidator_AssetPreloaded**: Fired when assets are preloaded

## Integration with Other Systems

### Core/Client Registry Integration

The AssetValidator automatically registers with the appropriate registry based on context:

```lua
if isClient then
    local ClientRegistry = safeRequire(findModule("ClientRegistry"))
    if ClientRegistry and ClientRegistry.registerSystem then
        ClientRegistry.registerSystem("AssetValidator", AssetValidator)
    end
end

if isServer then
    local CoreRegistry = safeRequire(findModule("CoreRegistry"))
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("AssetValidator", AssetValidator)
    end
end
```

### EventBridge Integration

The AssetValidator integrates with the EventBridge to fire events on validation:

```lua
if EventBridge.registerEvent then
    EventBridge.registerEvent("AssetValidator_AssetValidated")
    EventBridge.registerEvent("AssetValidator_AssetFailed")
    EventBridge.registerEvent("AssetValidator_AssetPreloaded")
end
```

## Best Practices

1. **Always Validate Asset IDs**: Use `AssetValidator.validateAssetId()` before setting asset IDs
2. **Provide Fallbacks for Critical Assets**: Register important fallbacks using `registerFallback`
3. **Preload Common Assets**: Use `preloadAssets` to queue frequently used assets for preloading
4. **Use Factory Methods**: Use `createImageLabel` and `createSound` for automatic validation
5. **Handle Both Client and Server**: Be aware of different behavior on client vs. server

## Performance Considerations

- The AssetValidator uses caching to avoid re-validating the same assets
- Asset preloading happens in a separate thread to avoid blocking
- Preloading is batched to reduce ContentProvider load
- Validation primarily happens on the client, with server-side using simplified checks

## Common Issues and Solutions

### Issue: Assets Not Displaying

**Possible causes:**
- Invalid asset IDs
- Assets not yet loaded
- Failure to handle validation results

**Solutions:**
- Use `validateAssetId()` to get a guaranteed valid ID or fallback
- Implement preloading for important assets
- Handle the possibility that a fallback might be used

### Issue: Performance Impact from Asset Loading

**Possible causes:**
- Too many assets loading simultaneously
- Large assets causing frame drops
- Repeated validation of the same assets

**Solutions:**
- Use the preloading system to spread out loading
- Cache validation results (built into the module)
- Prioritize smaller/compressed assets where possible

### Issue: Inconsistent Asset Appearance

**Possible causes:**
- Different fallbacks on client vs. server
- Race conditions in asset loading
- Validation failures not being handled

**Solutions:**
- Register consistent fallbacks for all asset types
- Use the module's factory methods (`createImageLabel`, `createSound`)
- Listen for validation events to detect failures

## Version History

- **1.0.0**: Initial release with core functionality
