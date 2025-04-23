--[[
    DynamicEconomy.server.luau
    This script handles the dynamic pricing of resources based on supply and demand.
]]

local DynamicEconomy = {}

-- Resource types
DynamicEconomy.ResourceTypes = {
    ENERGY = "Energy",
    RAW_MATERIAL = "RawMaterial",
    FINISHED_GOOD = "FinishedGood",
    EQUIPMENT = "Equipment",
    MEMBERSHIP = "Membership",
}

-- Resource data (initial prices, supply, demand)
DynamicEconomy.Resources = {
    [DynamicEconomy.ResourceTypes.ENERGY] = {
        Price = 10, -- Initial price
        Supply = 100, -- Initial supply
        Demand = 50, -- Initial demand
    },
    [DynamicEconomy.ResourceTypes.RAW_MATERIAL] = {
        Price = 5,
        Supply = 200,
        Demand = 100,
    },
    [DynamicEconomy.ResourceTypes.FINISHED_GOOD] = {
        Price = 20,
        Supply = 50,
        Demand = 25,
    },
    [DynamicEconomy.ResourceTypes.EQUIPMENT] = {
        Price = 50,
        Supply = 20,
        Demand = 10,
    },
    [DynamicEconomy.ResourceTypes.MEMBERSHIP] = {
        Price = 100,
        Supply = 10,
        Demand = 5,
    }
}

-- Function to update the supply of a resource
-- @param resourceType string: The type of resource to update.
-- @param supplyChange number: The amount to change the supply by (positive or negative).
function DynamicEconomy.UpdateSupply(resourceType, supplyChange)
    local resourceData = DynamicEconomy.Resources[resourceType]
    if not resourceData then
        warn("Invalid resource type: " .. resourceType)
        return
    end

    resourceData.Supply += supplyChange
    resourceData.Supply = math.max(0, resourceData.Supply) -- Ensure supply does not go below zero
    print("Updated supply for: ", resourceType, ". New Supply: ", resourceData.Supply)
end

-- Function to update the demand of a resource
-- @param resourceType string: The type of resource to update.
-- @param demandChange number: The amount to change the demand by (positive or negative).
function DynamicEconomy.UpdateDemand(resourceType, demandChange)
    local resourceData = DynamicEconomy.Resources[resourceType]
    if not resourceData then
        warn("Invalid resource type: " .. resourceType)
        return
    end

    resourceData.Demand += demandChange
    resourceData.Demand = math.max(0, resourceData.Demand) -- Ensure demand does not go below zero
    print("Updated demand for: ", resourceType, ". New Demand: ", resourceData.Demand)
end

-- Function to get the data of a specific resource
-- @param resourceType string: The type of resource to retrieve data for.
-- @return table: The resource data table containing 'Price', 'Supply', and 'Demand', or nil if the resource type is invalid.
function DynamicEconomy.GetResourceData(resourceType)
    local resourceData = DynamicEconomy.Resources[resourceType]
    if resourceData then
        return resourceData
    else
        warn("Invalid resource type: " .. resourceType)
        return nil
    end
end

-- Function to adjust the price of a resource based on supply and demand
-- @param resourceType string: The type of resource to adjust the price for.
function DynamicEconomy.AdjustPrice(resourceType)
    local resourceData = DynamicEconomy.Resources[resourceType]
    if not resourceData then
        warn("Invalid resource type: " .. resourceType)
        return
    end

    -- Calculate the supply-demand ratio
    local ratio = resourceData.Supply / (resourceData.Demand + 0.001) -- Adding a small value to avoid division by zero

    -- Adjust price based on the ratio
    if ratio > 1 then
        -- Supply is higher than demand, decrease price
        resourceData.Price = resourceData.Price * 0.95 -- Decrease price by 5%
    elseif ratio < 1 then
        -- Demand is higher than supply, increase price
        resourceData.Price = resourceData.Price * 1.05 -- Increase price by 5%
    end

    resourceData.Price = math.max(1, resourceData.Price) -- Ensure price does not fall below 1
    print("Price adjusted for: ", resourceType, ". New Price: ", resourceData.Price)
end

-- Function to get the current demand of a resource
function DynamicEconomy.GetResourceDemand(resourceType)
    local resourceData = DynamicEconomy.Resources[resourceType]
    if resourceData then
        return resourceData.Demand
    else
        warn("Invalid resource type: " .. resourceType)
        return nil
    end
end

-- Function to get the current supply of a resource
function DynamicEconomy.GetResourceSupply(resourceType)
    local resourceData = DynamicEconomy.Resources[resourceType]
    if resourceData then
        return resourceData.Supply
    else
        warn("Invalid resource type: " .. resourceType)
        return nil
    end
end

-- Function to get the current price of a resource
function DynamicEconomy.GetResourcePrice(resourceType)
    local resourceData = DynamicEconomy.Resources[resourceType]
    if resourceData then
        return resourceData.Price
    else
        warn("Invalid resource type: " .. resourceType)
        return nil
    end
end

-- Example usage (for testing, should be integrated into the game loop)
-- Adjust the price of each resource every 10 seconds
while task.wait(10) do
    for resourceType, _ in pairs(DynamicEconomy.Resources) do
        DynamicEconomy.AdjustPrice(resourceType)
    end
end

return DynamicEconomy