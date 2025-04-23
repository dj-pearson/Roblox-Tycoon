--[[
    BoundingBoxGenerator.server.luau
    
    ===== DEPRECATION NOTICE =====
    This script has been deprecated and is scheduled for removal.
    It has been consolidated into the new BoundingBoxManager.server.luau module.
    Please use BoundingBoxManager:GenerateHitboxes() instead of functionality from this script.
    See ConsolidationPlan.md for details on the module consolidation project.
    ===== END NOTICE =====
    
    Automatically creates and positions bounding boxes for equipment placement.
    Analyzes GymParts folder structure and floor layouts to determine logical
    placement zones for different types of equipment.
    
    Features:
    - Scans floor layouts to identify usable placement areas
    - Creates visual bounding boxes for equipment placement
    - Applies intelligent spacing rules based on equipment categories
    - Integrates with the modular BuyTile system for better placement guidance
    - Auto-detects wall orientations for equipment that needs wall placement
    
    Part of the consolidated modular system including:
    - FloorAttributeSetup - Floor and room structure management
    - BuyTileProgressionManager - Build order and prerequisites
    - TileDataGenerator - Attribute and data generation
    
    Author: Created April 2025
    Updated: April 21, 2025
]]

