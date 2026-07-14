--[[------------------------------------------------------------------------------------
   	
   DATASTORE SCHEMA MODULE
   
   @module Scheme
   @author mezz_inc
   @description Handles the layouts of the data stores values
   
   @within ServerScriptService/DataAPI
   
   
   Initialization
   
]]
------------------------------------------------------------------------------------

local Module = {}

--- Name of the module
local NAME: string = "Schema"

--- Access the Data API folder
local ServerScriptService = game:GetService("ServerScriptService")
local DataAPI = ServerScriptService:WaitForChild("DataAPI")

local SchemeLocation = script.Parent.Schemes

Module._meta = {
	name = NAME,
	version = "1.0.0",
	description = "Data-layouts for specific datastores",
}

--[[----------------------------------------------------------------------------------

	Modules

]]
----------------------------------------------------------------------------------

--- Dependant modules
local Debug = require(DataAPI.Debug)
local Types = require(DataAPI.Types)
local InstanceMapper = require(DataAPI.InstanceMapper)

--[[----------------------------------------------------------------------------------

	Types

]]
----------------------------------------------------------------------------------

type ValidStores = Types.ValidStores

--[[----------------------------------------------------------------------------------

	Debug
	Mostly wrapper functions for the Debug module

]]
----------------------------------------------------------------------------------

--- The source name of the module for debugging
local SOURCE_NAME: string = `[DataAPI.{NAME}]`

--- Prints out a debug message if debug is enabled
--- @param ... any? a variable number of arguments to prin
local function debugPrint(...)
	Debug.debugPrint(SOURCE_NAME, ...)
end

--- Warn a statement to the output
--- @param ... string? a variable number of strings/types to print
local function debugWarn(...)
	Debug.debugWarn(SOURCE_NAME, ...)
end

------------------------- Module

--[[----------------------------------------------------------------------------------

	Local Functions

]]
----------------------------------------------------------------------------------

--- Deep-merges two tables. Arrays (sequential integer keys) are replaced, not merged.
--- Skips the _served metadata key.
--- @param defaults {[any]: any} the base table with default values
--- @param overrides {[any]: any} the table with player-specific values
--- @return {[any]: any} merged the deep-merged result
local function deepMerge(defaults: { [any]: any }, overrides: { [any]: any }): { [any]: any }
	local result = {}
	for key, value in pairs(defaults) do
		if key == "_served" then
			continue
		end

		local overrideValue = overrides[key]
		if overrideValue ~= nil then
			if type(value) == "table" and type(overrideValue) == "table" then
				if InstanceMapper.isArray(overrideValue) or InstanceMapper.isArray(value) then
					result[key] = overrideValue
				else
					result[key] = deepMerge(value, overrideValue)
				end
			else
				result[key] = overrideValue
			end
		else
			result[key] = value
		end
	end
	return result
end

--- Returns whether or not a given scheme exists
--- @param dataStoreName string the name of the store to check
--- @return boolean exists whether it exists
local function schemeExists(dataStoreName: ValidStores | string): boolean
	return SchemeLocation:FindFirstChild(dataStoreName) ~= nil
end

--- Returns the schema for a given store name
--- @param dataStoreName string the name of the store to get the schema of
--- @return table schema the schema of the store
local function getSchemaForStore(dataStoreName: ValidStores | string): { [any]: any }
	local scheme = SchemeLocation:FindFirstChild(dataStoreName) :: Instance?
	if not scheme then
		debugWarn(`No scheme available for "{dataStoreName}" returning empty table!`)
		return {}
	end

	local schemeTable = require(scheme) :: { [any]: any }
	return schemeTable
end

--- Returns whether the store should be mirrored into the player's data folder
--- @param dataStoreName string the name of the store to inspect
--- @return boolean served whether the store is hot-served
local function isServedStore(dataStoreName: ValidStores | string): boolean
	local scheme = getSchemaForStore(dataStoreName)
	if scheme._served == nil then
		return true
	end
	return scheme._served == true
end

--- Returns whether the store is game mode specific
--- @param dataStoreName string the name of the store to inspect
--- @return boolean uniquePerGamemode whether the store is unique per gamemode
local function isGamemodeSpecificStore(dataStoreName: ValidStores | string): boolean
	local scheme = getSchemaForStore(dataStoreName)
	if not scheme or not next(scheme) then
		return true -- likely ordered with no schema, default to gamemode-specific
	end

	if scheme._uniquePerGamemode == nil then
		return false
	end
	return scheme._uniquePerGamemode == true
end

--- Creates a list from instance values based on their name, and current value.
--- Handles both flat Value instances and nested Folder hierarchies.
--- @param instanceList {Instance} the list of instances to convert
--- @return {[string]: any} table the table created from the instances
local function instancesToTable(
	instanceList: { Instance }
): { [string]: any }
	local newTable = {}
	for _, instance in ipairs(instanceList) do
		local instanceName = instance.Name :: string

		if instance:IsA("Folder") then
			newTable[instanceName] = InstanceMapper.instanceToValue(instance)
		elseif instance:IsA("ValueBase") then
			newTable[instanceName] = instance.Value
		else
			debugWarn("Unrecognized instance class:", instance.ClassName)
		end
	end

	return newTable
end

--- Returns a folder of values based on the input table, and the store name.
--- Delegates to InstanceMapper for unified flat and layered conversion.
--- By default has no parent
--- @param storeName string the name of the store to create the folder from
--- @param EntryTable {[string]: any} the table to create the folder from
--- @return Folder folder the folder created from the table
local function constructFolderFromEntryTable(storeName: string, EntryTable: { [string]: any }): Folder
	local cleaned = {}
	for key, value in pairs(EntryTable) do
		if key ~= "_served" then
			cleaned[key] = value
		end
	end

	return InstanceMapper.tableToFolder(storeName, cleaned)
end

--[[----------------------------------------------------------------------------------

	Function Mappers

]]
----------------------------------------------------------------------------------

Module.schemeExists = schemeExists
Module.getSchemaForStore = getSchemaForStore
Module.isServedStore = isServedStore
Module.isGamemodeSpecificStore = isGamemodeSpecificStore
Module.instancesToTable = instancesToTable
Module.constructFolderFromEntryTable = constructFolderFromEntryTable
Module.deepMerge = deepMerge

--[[----------------------------------------------------------------------------------

	Start & Test Features

]]
----------------------------------------------------------------------------------

--- Initalization function
local function start() end

--- Runs a developer test on the module
local function test() end

--[[----------------------------------------------------------------------------------

	END

]]
----------------------------------------------------------------------------------

--- Calling module.start() will start the module
--- Calling module.test() will test a function of the module
Module.start = start
Module.test = test

return Module
