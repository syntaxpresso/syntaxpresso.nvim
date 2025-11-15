local command_runner = require("syntaxpresso.utils.command_runner")
local context = require("syntaxpresso.utils.context")

local M = {}

---Extract value from signal or return as-is
---@param value any
---@return any
local function get_signal_value(value)
	if type(value) == "table" and value.get_value then
		return value:get_value()
	end
	return value
end

---Transform cascade types from UI format to CLI format
---@param cascades table|nil
---@return table
local function transform_cascades(cascades)
	if not cascades or #cascades == 0 then
		return {}
	end
	local result = {}
	for _, cascade in ipairs(cascades) do
		table.insert(result, string.lower(cascade))
	end
	return result
end

---Transform other options from UI format to CLI format
---@param other table|nil
---@return table
local function transform_other(other)
	if not other or #other == 0 then
		return {}
	end
	local result = {}
	for _, opt in ipairs(other) do
		table.insert(result, string.lower(opt))
	end
	return result
end

---Create a JPA one-to-one relationship
---@param relationship_config table Relationship configuration from UI
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings
function M.create_jpa_one_to_one_relationship(relationship_config, callback, options)
	-- Validate required parameters
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end

	-- Get fresh context from the current buffer
	local ctx = context.get_buffer_context(0)

	if not ctx.entity_file_path or ctx.entity_file_path == "" then
		callback(nil, "Entity file path is required")
		return
	end

	-- Extract signal values
	local owning_side_field_name = get_signal_value(relationship_config.owning_side_field_name)
	local inverse_side_field_name = get_signal_value(relationship_config.inverse_side_field_name)
	local inverse_field_type = get_signal_value(relationship_config.inverse_field_type)
	local mapping_type = get_signal_value(relationship_config.mapping_type)
	local owning_side_cascades = get_signal_value(relationship_config.owning_side_cascades)
	local inverse_side_cascades = get_signal_value(relationship_config.inverse_side_cascades)
	local owning_side_other = get_signal_value(relationship_config.owning_side_other)
	local inverse_side_other = get_signal_value(relationship_config.inverse_side_other)

	-- Validate required fields
	if not owning_side_field_name or owning_side_field_name == "" then
		callback(nil, "Owning side field name is required")
		return
	end

	if not inverse_side_field_name or inverse_side_field_name == "" then
		callback(nil, "Inverse side field name is required")
		return
	end

	if not inverse_field_type or inverse_field_type == "" then
		callback(nil, "Inverse field type is required")
		return
	end

	-- Build arguments
	local args = {
		cwd = ctx.cwd,
		["owning-side-entity-file-b64-src"] = ctx.entity_file_b64_src,
		["owning-side-entity-file-path"] = ctx.entity_file_path,
		["owning-side-field-name"] = owning_side_field_name,
		["inverse-side-field-name"] = inverse_side_field_name,
		["inverse-field-type"] = inverse_field_type,
	}

	-- Add optional mapping type
	if mapping_type and mapping_type ~= "" then
		args["mapping-type"] = string.lower(mapping_type)
	end

	-- Add cascade types
	if owning_side_cascades and #owning_side_cascades > 0 then
		args["owning-side-cascades"] = transform_cascades(owning_side_cascades)
	end

	if inverse_side_cascades and #inverse_side_cascades > 0 then
		args["inverse-side-cascades"] = transform_cascades(inverse_side_cascades)
	end

	-- Add other options
	if owning_side_other and #owning_side_other > 0 then
		args["owning-side-other"] = transform_other(owning_side_other)
	end

	if inverse_side_other and #inverse_side_other > 0 then
		args["inverse-side-other"] = transform_other(inverse_side_other)
	end

	-- Execute command
	command_runner.execute("create-jpa-one-to-one-relationship", args, callback, options)
end

return M
