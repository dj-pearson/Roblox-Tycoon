# Gym Tycoon Structure Documentation

_Created: April 20, 2025_ - 

This document outlines the architectural organization of the Gym Tycoon game, focusing on the physical structure organization and how it integrates with the BuyTileSystem and floor attributes.

## 1. Physical Structure Organization

The game uses a hierarchical folder structure to organize gym elements:

```
# GymParts Directory

## 1st Floor
- Accessories
- Cardio
- Ceiling
- Concession
- Functional
- Furniture
- Juice Bar
- Kids Gym
- LockerRoom
- Sport
- Strength
- Walls
- 📄 Stairs - 1st

## 2nd Floor
- 2nd Floor Terrace
- Aquarium
- Basketball
- Ceiling
- Accessories
- Furniture
- Games
- Golf Sim and Lounge
- Group Fitness
- HIIT
- Spin
- Walls
- 📄 Stairs - 2nd_152

## 3rd Floor
- 3rd Floor Terrace
- Ceiling
- Accessories
- Massage and Wellness
- PT Studio
- Pilates Studio
- Walls
- Yoga
- Yoga - 2
- 📄 Stairs - 3rd_154

## 4th Floor
- 4th Floor Terrace
- Boxing
- Ceiling
- Rock Wall
- Pool
- Offices
- Restaurant
- Shower Mens
- Shower Womens
- Walls
- 📄 Stairs - 4th_156

## Elevator

## Floor

## Outside
- Accessories
- Parking Lot
- Playground
- Yoga
- Soccer Field
- Skate Park
- Stage
- Pickleball Court
- Tennis Court
- Rock Wall
- Front
- Pool
- Sidewalk
- Surround
- Walls
- 📄 Outside Floor
- 📄 Sidewalk Front 30

## Roof
- Pool Area
- Track Area
- Walls


## 2. Attribute System

All objects within the gym use an attribute-based system for quick identification and categorization:

### Floor Attributes

- `Floor`: Numeric value (1-6) representing the floor number
- `FloorName`: String ("1st", "2nd", etc.) for display in UI elements
- These attributes are automatically applied based on the parent folder

### Room Attributes

- `Room`: String identifying which room the object belongs to
- Objects inherit this attribute from their parent room folder

### Category Attributes

- `Category`: Equipment category (Structure, Cardio, Strength, etc.)
- Used for organizing purchases and gameplay progression

### Placement Attributes

- `NeedsWall`: Boolean indicating if equipment must be placed against a wall
- `IsCorner`: Boolean indicating if item should be placed in corner areas
- `ClearanceRequired`: Number indicating space needed around equipment

## 3. Integration with BuyTileSystem

The BuyTileSystem integrates with this physical structure to create a logical progression system:

### Floor Progression

1. **Sequential Floor Unlocking**

   - Floors are unlocked in sequence (1st → 2nd → 3rd → 4th → Roof → Outside)
   - Each floor requires completion of key elements on the previous floor
   - Stairs or elevators act as gateway purchases between floors

2. **Floor Completion Requirements**
   - Every floor has "required" purchases before it's considered complete
   - Required items are tagged with `isRequired = true` in BuyTileSystem
   - Structure elements (walls, floor) always come first in the build order

### Room-Based Organization

1. **Room Unlock Sequence**

   - Rooms on each floor follow a logical unlock sequence
   - Entrance → Main Areas → Specialized Areas → Amenities
   - Room completion triggers events for game progression

2. **Equipment Placement Logic**
   - Equipment is placed in appropriate rooms based on category
   - Cardio equipment goes in Cardio Zones
   - Strength equipment goes in Strength Training areas
   - Specialty equipment has dedicated areas

## 4. Automated Attribute Setup

The `FloorAttributeSetup` script automatically:

1. **Sets Floor Attributes**

   - Scans the GymParts structure on game start
   - Applies Floor and FloorName attributes to all objects
   - Maintains attributes when new objects are added

2. **Integrates with BuyTileSystem**

   - Extends BuyTileSystem with floor-aware methods
   - Provides helpers like `GetFloorName` and `HasUnlockedFloorByName`
   - Auto-generates tile data attributes from physical models

3. **Provides Administrative Tools**
   - `/setFloorAttributes` command for manual attribute refresh
   - `/setFloor [path] [number]` command for specific object updates
   - `/processGymParts` command specifically for GymParts folder

## 5. TileDataGenerator Features

The `TileDataGenerator` script automates BuyTileSystem data generation:

1. **Model Scanning**

   - Scans model files in ServerStorage folders
   - Extracts embedded attributes from models
   - Auto-categorizes equipment based on naming patterns

2. **Data Generation**

   - Creates BuyTileSystem.tileData entries
   - Determines appropriate build orders
   - Generates logical prerequisites
   - Sets default price points based on complexity

3. **Commandline Interface**
   - `/generateTileData` updates BuyTileSystem in real-time
   - `/generateTileData true` exports to external file for backup

## 6. BoundingBoxGenerator Features

The `BoundingBoxGenerator` helps with equipment placement:

1. **Smart Placement**

   - Analyzes floor layouts for optimal placement spots
   - Considers equipment category requirements (wall adjacency, corner placement)
   - Respects spacing requirements between equipment

2. **Visual Guidance**

   - Creates visual bounding boxes for placement preview
   - Color-codes boxes based on category
   - Shows equipment names and dimensions

3. **Command Interface**
   - `/generateBoundingBoxes` creates guides for all equipment
   - `/generateBoundingBoxes [type]` for specific equipment
   - `/clearBoundingBoxes` to hide when not needed

## 7. Progression System

The BuyTileSystem enforces progression based on:

### Build Order Logic

- `buildOrder` property determines sequence within each floor
- Lower numbers must be built before higher numbers
- Structure (1-100) → Basic Equipment (101-200) → Advanced (201+)

### Prerequisites System

- Each item can have prerequisites that must be purchased first
- Prerequisites can be specific items or completion of an entire floor
- Prerequisites are defined both in code and through model attributes

### Floor Gating

- Higher floors require "gateway" purchases (stairs, elevators)
- Gateway items set the `unlocksFloor` attribute to the next floor
- Each floor has a minimum set of required items before gateway unlocks

## 8. Implementation Guidelines

When expanding or modifying the gym:

1. **Adding New Equipment**

   - Place physical model in appropriate room folder
   - Set basic attributes (Category, BuildOrder, etc.) on the model
   - Run `/generateTileData` to update BuyTileSystem

2. **Creating New Floors**

   - Create new folder with proper floor name (e.g., "5th Floor")
   - Add standard subfolders (Rooms, Walls, Floor, Ceiling)
   - Create room folders for specialized areas
   - Run `/processGymParts` to update attributes

3. **Modifying Progression**
   - Update BuildOrder numbers to change sequence
   - Modify Prerequisites lists for dependency changes
   - Set IsRequired=true for critical path items
   - Set UnlocksFloor attribute on gateway items

## 9. Script Interface Reference

### FloorAttributeSetup

```lua
-- Get floor name from number
local floorName = BuyTileSystem:GetFloorName(2) -- Returns "2nd"

-- Check if player has unlocked floor by name
local hasUnlocked = BuyTileSystem:HasUnlockedFloorByName(player, "2nd")

-- Get all available floors with their data
local allFloors = BuyTileSystem:GetAllFloors()
```

### TileDataGenerator

```lua
-- Generate tile data for all models
TileDataGenerator:UpdateBuyTileSystem()

-- Export tile data to file
local dataScript = TileDataGenerator:ExportTileDataToFile()

-- Extract model attributes
local attrs = TileDataGenerator:ExtractModelAttributes(model)
```

### BoundingBoxGenerator

```lua
-- Generate bounding boxes for all equipment
BoundingBoxGenerator:GenerateAllBoundingBoxes(tycoon)

-- Generate boxes for specific type
BoundingBoxGenerator:GenerateBoundingBoxesForType("Treadmill", tycoon)

-- Show/hide existing boxes
BoundingBoxGenerator:SetBoxesVisibility(true, tycoon)
```

## 10. Future Extensions

The system is designed to support these future enhancements:

1. **Dynamic Floor Generation**

   - Procedural layout generation based on difficulty level
   - Adaptive gym sizing based on player progression

2. **Specialized Floor Themes**

   - Themed floors with unique visual styles
   - Special equipment sets for themed floors

3. **Auto-Placement System**

   - AI-driven equipment placement recommendations
   - Optimal layout suggestions based on space utilization

4. **Progression Visualization**
   - Visual progress indicators by floor/room
   - Interactive purchase guides in 3D space
