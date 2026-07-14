--[[------------------------------------------------------------------------------------

    INSTANCE MAPPER MODULE

    @module InstanceMapper
    @author mezz_inc
    @description Converts nested Lua tables into Folder/Value instance hierarchies and back.
                 Supports dictionaries (Folder children), ordered arrays (Folder with
                 numerically-named StringValue children), and primitives (StringValue,
                 NumberValue, BoolValue).

    @within ServerScriptService/DataAPI

    Mapping:
        string   -> StringValue
        number   -> NumberValue
        bool     -> BoolValue
        dict {}  -> Folder (children named by dictionary key)
        array {} -> Folder (children named "1", "2", ... by 1-based index)

]]
------------------------------------------------------------------------------------

local InstanceMapper = {}

local VALUE_CLASSES = {
	["StringValue"] = true,
	["NumberValue"] = true,
	["BoolValue"] = true,
}

--- Determines if a table is a sequential 1-indexed array
--- @param t table the table to check
--- @return boolean whether the table is an array
local function isArray(t: { [any]: any }): boolean
	local count = 0
	for k, _ in pairs(t) do
		count += 1
		if type(k) ~= "number" or k ~= count then
			return false
		end
	end
	return count > 0 and count == #t
end

InstanceMapper.isArray = isArray

--- Recursively converts a Lua value into an Instance
--- @param key string|number the name for the created instance
--- @param value any the Lua value to convert
--- @return Instance instance the created instance
local function valueToInstance(key: string | number, value: any): Instance
	local valueType = type(value)

	if valueType == "string" then
		local inst = Instance.new("StringValue")
		inst.Name = tostring(key)
		inst.Value = value
		return inst
	elseif valueType == "number" then
		local inst = Instance.new("NumberValue")
		inst.Name = tostring(key)
		inst.Value = value
		return inst
	elseif valueType == "boolean" then
		local inst = Instance.new("BoolValue")
		inst.Name = tostring(key)
		inst.Value = value
		return inst
	elseif valueType == "table" then
		local folder = Instance.new("Folder")
		folder.Name = tostring(key)

		if isArray(value) then
			for i, childValue in ipairs(value) do
				local child = valueToInstance(i, childValue)
				child.Parent = folder
			end
		else
			for childKey, childValue in pairs(value) do
				local child = valueToInstance(childKey, childValue)
				child.Parent = folder
			end
		end

		return folder
	else
		error(`Unsupported value type: {valueType}`)
	end
end

--- Recursively converts an Instance back into a Lua value
--- @param instance Instance the instance to convert
--- @return any value the reconstructed Lua value
local function instanceToValue(instance: Instance): any
	local className = instance.ClassName

	if className == "StringValue" or className == "NumberValue" or className == "BoolValue" then
		return instance.Value
	elseif className == "Folder" then
		local children = instance:GetChildren()

		if #children == 0 then
			return {}
		end

		local allNumeric = true
		for i, child in ipairs(children) do
			if tonumber(child.Name) ~= i then
				allNumeric = false
				break
			end
		end

		if allNumeric then
			table.sort(children, function(a, b)
				return tonumber(a.Name) < tonumber(b.Name)
			end)
			local arr = {}
			for _, child in ipairs(children) do
				table.insert(arr, instanceToValue(child))
			end
			return arr
		else
			local dict = {}
			for _, child in ipairs(children) do
				dict[child.Name] = instanceToValue(child)
			end
			return dict
		end
	end

	warn(`Unrecognized instance class: {className}`)
	return nil
end

--- Converts a nested Lua table into a Folder instance hierarchy
--- @param name string the name of the root folder
--- @param data {[string]: any} the table to convert
--- @return Folder folder the root folder containing the mapped hierarchy
function InstanceMapper.tableToFolder(name: string, data: { [any]: any }): Folder
	local root = Instance.new("Folder")
	root.Name = name

	for key, value in pairs(data) do
		local child = valueToInstance(key, value)
		child.Parent = root
	end

	return root
end

--- Converts a Folder instance hierarchy back into a nested Lua table
--- @param folder Folder the root folder to convert
--- @return {[string]: any} table the reconstructed table
function InstanceMapper.folderToTable(folder: Folder): { [string]: any }
	local result = {}
	for _, child in ipairs(folder:GetChildren()) do
		result[child.Name] = instanceToValue(child)
	end
	return result
end

--- Converts a single Lua value into an Instance (exposed for selective use)
--- @param key string|number the name for the instance
--- @param value any the value to convert
--- @return Instance instance the created instance
function InstanceMapper.valueToInstance(key: string | number, value: any): Instance
	return valueToInstance(key, value)
end

--- Converts a single Instance back into a Lua value (exposed for selective use)
--- @param instance Instance the instance to convert
--- @return any value the reconstructed value
function InstanceMapper.instanceToValue(instance: Instance): any
	return instanceToValue(instance)
end

--- Prints a readable tree of the instance hierarchy (debug helper)
--- @param instance Instance the root instance to print
--- @param indent number? the current indentation level (default 0)
function InstanceMapper.printHierarchy(instance: Instance, indent: number?)
	indent = indent or 0
	local prefix = string.rep("  ", indent)

	local valueStr = ""
	if VALUE_CLASSES[instance.ClassName] then
		valueStr = ` = {tostring(instance.Value)}`
	end

	print(`{prefix}{instance.ClassName} "{instance.Name}"{valueStr}`)

	for _, child in ipairs(instance:GetChildren()) do
		InstanceMapper.printHierarchy(child, indent + 1)
	end
end

return InstanceMapper
