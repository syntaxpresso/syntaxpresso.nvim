local command_runner = require("syntaxpresso.utils.command_runner")
local context = require("syntaxpresso.utils.context")

local M = {}

---Transform enum type storage value from UI format (uppercase) to CLI format (lowercase)
---@param enum_type_storage string|nil
---@return string|nil
local function transform_enum_type_storage(enum_type_storage)
	if not enum_type_storage or enum_type_storage == "" then
		return nil
	end
	return string.lower(enum_type_storage)
end

---Parse string number to number or return nil
---@param str_num string|nil
---@return number|nil
local function parse_number(str_num)
	if not str_num or str_num == "" then
		return nil
	end
	local num = tonumber(str_num)
	return num
end

---Check if value exists in array
---@param arr table
---@param value string
---@return boolean
local function contains(arr, value)
	for _, v in ipairs(arr) do
		if v == value then
			return true
		end
	end
	return false
end

---Create a JPA entity enum field
---@param field_config table Field configuration from UI
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings
function M.create_jpa_entity_enum_field(field_config, callback, options)
	-- Validate required parameters
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end

	-- Get fresh context from the specified buffer
	local ctx = context.get_buffer_context(0)

	if not ctx.entity_file_path or ctx.entity_file_path == "" then
		callback(nil, "Entity file path is required")
		return
	end

	if not field_config.field_name or field_config.field_name == "" then
		callback(nil, "Field name is required")
		return
	end

	if not field_config.field_type or field_config.field_type == "" then
		callback(nil, "Enum type is required")
		return
	end

	if not field_config.field_package_path or field_config.field_package_path == "" then
		callback(nil, "Enum package name is required")
		return
	end

	if not field_config.enum_type_storage or field_config.enum_type_storage == "" then
		callback(nil, "Enum type storage is required")
		return
	end

	-- Extract 'other' array to determine boolean flags
	local other = field_config.other or {}
	local is_mandatory = contains(other, "mandatory")
	local is_unique = contains(other, "unique")

	-- Build arguments
	local args = {
		cwd = ctx.cwd,
		["entity-file-b64-src"] = ctx.entity_file_b64_src,
		["entity-file-path"] = ctx.entity_file_path,
		["field-name"] = field_config.field_name,
		["enum-type"] = field_config.field_type,
		["enum-package-name"] = field_config.field_package_path,
		["enum-type-storage"] = transform_enum_type_storage(field_config.enum_type_storage),
	}

	-- Add optional field-length
	local length = parse_number(field_config.field_length)
	if length then
		args["field-length"] = length
	end

	-- Add boolean flags
	if is_unique then
		args["field-unique"] = true
	end

	-- Note: field-nullable is INVERTED from mandatory
	if not is_mandatory then
		args["field-nullable"] = true
	end

	-- Execute command
	command_runner.execute("create-jpa-entity-enum-field", args, callback, options)
end

return M
