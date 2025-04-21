--[[
    ModelValidator.server.luau
    
    Validates game models for common issues and ensures they meet standards for the Gym Tycoon.
    Checks for:
    - Missing PrimaryPart
    - Unanchored parts 
    - Excessive part counts
    - Naming convention compliance
    - Required attribute presence
    
    Part of the automated model validation & linting system.
    
    Author: Created April 21, 2025
]]

local CollectionService = game:GetService("CollectionService")

-- Configuration constants
local ModelValidator = {
    MAX_PARTS_WARNING = 50,    -- Show warning if model exceeds this part count
    MAX_PARTS_ERROR = 100,     -- Flag as error if model exceeds this part count
    REQUIRED_ATTRIBUTES = {    -- Attributes that should be present on models
        EQUIPMENT = {"Category", "Price", "IncomeBoost"},
        STRUCTURE = {"Category", "Floor"},
        DEFAULT = {"Category"}
    },
    NAMING_PATTERNS = {        -- Regex patterns for model naming conventions
        EQUIPMENT = "^[A-Z][%w_]+%d*$",         -- e.g. Treadmill2, BenchPress, SquatRack_1
        STRUCTURE = "^[A-Z][%w_]+$",           -- e.g. Wall, Floor, Reception
        NPC = "^NPC_[%w_]+$"                   -- e.g. NPC_RegularMember
    }
}

-- Validator for PrimaryPart issues
function ModelValidator:ValidatePrimaryPart(model)
    local issues = {}
    
    if not model.PrimaryPart then
        table.insert(issues, {
            severity = "ERROR",
            message = "Missing PrimaryPart",
            detail = "This model has no PrimaryPart set, which is required for proper placement and CFrame operations"
        })
    end
    
    return issues
end

-- Validator for anchoring issues
function ModelValidator:ValidateAnchoring(model)
    local issues = {}
    local unanchoredParts = {}
    
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored then
            table.insert(unanchoredParts, part.Name)
        end
    end
    
    if #unanchoredParts > 0 then
        -- For structures, unanchored parts are an error
        local severity = "WARNING"
        if model:GetAttribute("Category") == "STRUCTURE" then
            severity = "ERROR"
        end
        
        table.insert(issues, {
            severity = severity,
            message = "Unanchored parts detected",
            detail = "The following parts are not anchored: " .. table.concat(unanchoredParts, ", "),
            parts = unanchoredParts
        })
    end
    
    return issues
end

-- Validator for part count
function ModelValidator:ValidatePartCount(model)
    local issues = {}
    local parts = 0
    
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            parts = parts + 1
        end
    end
    
    if parts > self.MAX_PARTS_ERROR then
        table.insert(issues, {
            severity = "ERROR",
            message = "Excessive part count",
            detail = "Model contains " .. parts .. " parts, which exceeds the maximum recommended count of " .. self.MAX_PARTS_ERROR
        })
    elseif parts > self.MAX_PARTS_WARNING then
        table.insert(issues, {
            severity = "WARNING",
            message = "High part count",
            detail = "Model contains " .. parts .. " parts, which may impact performance"
        })
    end
    
    return issues
end

-- Validator for naming conventions
function ModelValidator:ValidateNaming(model)
    local issues = {}
    local modelName = model.Name
    local category = model:GetAttribute("Category") or "DEFAULT"
    
    local pattern = self.NAMING_PATTERNS[category] or self.NAMING_PATTERNS.DEFAULT
    
    if pattern and not string.match(modelName, pattern) then
        table.insert(issues, {
            severity = "WARNING",
            message = "Naming convention violated",
            detail = "Model name '" .. modelName .. "' does not follow the " .. category .. " naming convention pattern"
        })
    end
    
    return issues
end

-- Validator for required attributes
function ModelValidator:ValidateAttributes(model)
    local issues = {}
    local category = model:GetAttribute("Category") or "DEFAULT"
    
    local requiredAttributes = self.REQUIRED_ATTRIBUTES[category] or self.REQUIRED_ATTRIBUTES.DEFAULT
    local missingAttributes = {}
    
    for _, attr in ipairs(requiredAttributes) do
        if model:GetAttribute(attr) == nil then
            table.insert(missingAttributes, attr)
        end
    end
    
    if #missingAttributes > 0 then
        table.insert(issues, {
            severity = "ERROR",
            message = "Missing required attributes",
            detail = "Model is missing the following required attributes: " .. table.concat(missingAttributes, ", ")
        })
    end
    
    return issues
end

-- Function to validate a single model
function ModelValidator:ValidateModel(model)
    if not model:IsA("Model") then
        return {
            valid = false,
            issues = {{
                severity = "ERROR",
                message = "Not a model instance",
                detail = model.Name .. " is a " .. model.ClassName .. ", not a Model"
            }}
        }
    end
    
    local allIssues = {}
    
    -- Run all validators
    local primaryPartIssues = self:ValidatePrimaryPart(model)
    local anchoringIssues = self:ValidateAnchoring(model)
    local partCountIssues = self:ValidatePartCount(model)
    local namingIssues = self:ValidateNaming(model)
    local attributeIssues = self:ValidateAttributes(model)
    
    -- Combine all issues
    for _, issue in ipairs(primaryPartIssues) do
        table.insert(allIssues, issue)
    end
    
    for _, issue in ipairs(anchoringIssues) do
        table.insert(allIssues, issue)
    end
    
    for _, issue in ipairs(partCountIssues) do
        table.insert(allIssues, issue)
    end
    
    for _, issue in ipairs(namingIssues) do
        table.insert(allIssues, issue)
    end
    
    for _, issue in ipairs(attributeIssues) do
        table.insert(allIssues, issue)
    end
    
    local hasErrors = false
    for _, issue in ipairs(allIssues) do
        if issue.severity == "ERROR" then
            hasErrors = true
            break
        end
    end
    
    -- Add a tag to models with issues
    if #allIssues > 0 then
        CollectionService:AddTag(model, "ModelHasIssues")
    else
        CollectionService:RemoveTag(model, "ModelHasIssues")
    end
    
    -- Add specific tags for models with errors vs warnings
    if hasErrors then
        CollectionService:AddTag(model, "ModelHasErrors")
    else
        CollectionService:RemoveTag(model, "ModelHasErrors")
    end
    
    return {
        valid = #allIssues == 0,
        hasErrors = hasErrors,
        issues = allIssues
    }
end

-- Function to validate all models in a container
function ModelValidator:ValidateAllModels(container)
    local results = {
        valid = true,
        modelsChecked = 0,
        modelsWithIssues = 0,
        modelsWithErrors = 0,
        totalIssues = 0,
        issues = {}
    }
    
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("Model") then
            -- Skip models that are children of other models that were already validated
            local parentModel = child.Parent
            while parentModel ~= nil and parentModel ~= container do
                if parentModel:IsA("Model") then
                    -- This is a sub-model, skip it
                    goto continue
                end
                parentModel = parentModel.Parent
            end
            
            results.modelsChecked = results.modelsChecked + 1
            
            local modelResult = self:ValidateModel(child)
            
            if not modelResult.valid then
                results.valid = false
                results.modelsWithIssues = results.modelsWithIssues + 1
                
                if modelResult.hasErrors then
                    results.modelsWithErrors = results.modelsWithErrors + 1
                end
                
                results.totalIssues = results.totalIssues + #modelResult.issues
                
                results.issues[child.Name] = modelResult.issues
            end
        end
        
        ::continue::
    end
    
    return results
end

-- Function to tag all valid equipment by category
function ModelValidator:TagModelsByCategory(container)
    local tagCounts = {}
    
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("Model") then
            local category = child:GetAttribute("Category")
            if category then
                local tagName = category .. "Equipment"
                
                -- Only tag models with no errors
                if not CollectionService:HasTag(child, "ModelHasErrors") then
                    if not CollectionService:HasTag(child, tagName) then
                        CollectionService:AddTag(child, tagName)
                        
                        tagCounts[tagName] = (tagCounts[tagName] or 0) + 1
                    end
                    
                    -- Also tag with floor if available
                    local floor = child:GetAttribute("Floor")
                    if floor then
                        local floorTag = "Floor" .. floor
                        if not CollectionService:HasTag(child, floorTag) then
                            CollectionService:AddTag(child, floorTag)
                            tagCounts[floorTag] = (tagCounts[floorTag] or 0) + 1
                        end
                    end
                end
            end
        end
    end
    
    return tagCounts
end

-- Function to display issues in a more readable format (for debugging)
function ModelValidator:PrintIssues(results)
    print("\n=== MODEL VALIDATION RESULTS ===")
    print("Models checked: " .. results.modelsChecked)
    print("Models with issues: " .. results.modelsWithIssues)
    print("Models with errors: " .. results.modelsWithErrors)
    print("Total issues found: " .. results.totalIssues)
    print("")
    
    if results.totalIssues == 0 then
        print("✓ All models passed validation!")
        return
    end
    
    for modelName, issues in pairs(results.issues) do
        print("MODEL: " .. modelName)
        
        for _, issue in ipairs(issues) do
            local prefix = issue.severity == "ERROR" and "✖ ERROR: " or "⚠ WARNING: "
            print("  " .. prefix .. issue.message)
            print("    " .. issue.detail)
        end
        
        print("")
    end
end

-- Function to create a validation report as a string
function ModelValidator:GenerateReport(results)
    local report = "=== MODEL VALIDATION REPORT ===\n"
    report = report .. "Models checked: " .. results.modelsChecked .. "\n"
    report = report .. "Models with issues: " .. results.modelsWithIssues .. "\n"
    report = report .. "Models with errors: " .. results.modelsWithErrors .. "\n"
    report = report .. "Total issues found: " .. results.totalIssues .. "\n\n"
    
    if results.totalIssues == 0 then
        report = report .. "✓ All models passed validation!\n"
        return report
    end
    
    for modelName, issues in pairs(results.issues) do
        report = report .. "MODEL: " .. modelName .. "\n"
        
        for _, issue in ipairs(issues) do
            local prefix = issue.severity == "ERROR" and "✖ ERROR: " or "⚠ WARNING: "
            report = report .. "  " .. prefix .. issue.message .. "\n"
            report = report .. "    " .. issue.detail .. "\n"
        end
        
        report = report .. "\n"
    end
    
    return report
end

return ModelValidator