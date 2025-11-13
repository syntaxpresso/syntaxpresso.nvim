local command_runner = require("syntaxpresso.utils.command_runner")

local M = {}

---Transform temporal value from UI format (uppercase) to CLI format (lowercase)
---@param temporal string|nil
---@return string|nil
local function transform_temporal(temporal)
	if not temporal or temporal == "" then
		return nil
	end
	return string.lower(temporal)
end

---Transform timezone storage value from UI format to CLI format
---@param timezone_storage string|nil
---@return string|nil
local function transform_timezone_storage(timezone_storage)
	if not timezone_storage or timezone_storage == "" then
		return nil
	end
	return string.lower(timezone_storage)
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

---Create a JPA entity basic field
---@param field_config table Field configuration from UI
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings
function M.create_jpa_entity_basic_field(cwd, entity_file_b64_src, entity_file_path, field_config, callback, options)
	-- Validate required parameters
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end

	if not entity_file_path or entity_file_path == "" then
		callback(nil, "Entity file path is required")
		return
	end

	if not field_config.field_name or field_config.field_name == "" then
		callback(nil, "Field name is required")
		return
	end

	if not field_config.field_type or field_config.field_type == "" then
		callback(nil, "Field type is required")
		return
	end

	-- Extract 'other' array to determine boolean flags
	local other = field_config.other or {}
	local is_mandatory = contains(other, "mandatory")
	local is_unique = contains(other, "unique")
	local is_large_object = contains(other, "large_object")

	-- Build arguments
	local args = {
		cwd = cwd,
		["entity-file-b64-src"] = entity_file_b64_src,
		["entity-file-path"] = entity_file_path,
		["field-name"] = field_config.field_name,
		["field-type"] = field_config.field_type,
	}

	-- Add optional field-type-package-name
	if field_config.field_package_path and field_config.field_package_path ~= "" then
		args["field-type-package-name"] = field_config.field_package_path
	end

	-- Add optional numeric fields
	local length = parse_number(field_config.field_length)
	if length then
		args["field-length"] = length
	end

	local precision = parse_number(field_config.field_precision)
	if precision then
		args["field-precision"] = precision
	end

	local scale = parse_number(field_config.field_scale)
	if scale then
		args["field-scale"] = scale
	end

	-- Add optional temporal field (transform to lowercase)
	local temporal = transform_temporal(field_config.field_temporal)
	if temporal then
		args["field-temporal"] = temporal
	end

	-- Add optional timezone storage (transform to lowercase)
	local timezone_storage = transform_timezone_storage(field_config.field_time_zone_storage)
	if timezone_storage then
		args["field-timezone-storage"] = timezone_storage
	end

	-- Add boolean flags
	if is_unique then
		args["field-unique"] = true
	end

	-- Note: field-nullable is INVERTED from mandatory
	if not is_mandatory then
		args["field-nullable"] = true
	end

	if is_large_object then
		args["field-large-object"] = true
	end

	-- Execute command
	command_runner.execute("create-jpa-entity-basic-field", args, callback, options)
end

return M
