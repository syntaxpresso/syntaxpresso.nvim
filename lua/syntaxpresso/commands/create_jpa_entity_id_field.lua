local command_runner = require("syntaxpresso.utils.command_runner")
local context = require("syntaxpresso.utils.context")

local M = {}

---Transform id generation value from UI format to CLI format
---@param id_generation string|nil
---@return string|nil
local function transform_id_generation(id_generation)
	if not id_generation or id_generation == "" then
		return nil
	end
	return string.lower(id_generation)
end

---Transform id generation type value from UI format to CLI format
---@param id_generation_type string|nil
---@return string|nil
local function transform_id_generation_type(id_generation_type)
	if not id_generation_type or id_generation_type == "" then
		return nil
	end
	return string.lower(id_generation_type)
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

---Create a JPA entity ID field
---@param field_config table Field configuration from UI
---@param callback fun(response: table|nil, error: string|nil) Callback function
---@param options table|nil Optional settings (should include source_bufnr)
function M.create_jpa_entity_id_field(field_config, callback, options)
	-- Validate required parameters
	if not callback or type(callback) ~= "function" then
		error("Callback function is required")
	end

	-- Get the source buffer number from options, fallback to current buffer
	local bufnr = (options and options.source_bufnr) or 0

	-- Ensure bufnr is a valid number (convert if needed, fallback to 0)
	if type(bufnr) ~= "number" then
		bufnr = tonumber(bufnr) or 0
	end

	-- Validate that buffer exists and is valid
	if bufnr ~= 0 and not vim.api.nvim_buf_is_valid(bufnr) then
		callback(nil, "Invalid buffer: buffer does not exist or has been closed")
		return
	end

	-- Get fresh context from the specified buffer
	local ctx = context.get_buffer_context(bufnr)

	if not ctx.entity_file_path or ctx.entity_file_path == "" then
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

	if not field_config.id_generation or field_config.id_generation == "" then
		callback(nil, "ID generation is required")
		return
	end

	if not field_config.id_generation_type or field_config.id_generation_type == "" then
		callback(nil, "ID generation type is required")
		return
	end

	-- Extract 'other' array to determine boolean flags
	local other = field_config.other or {}
	local is_mandatory = contains(other, "mandatory")

	-- Build arguments
	local args = {
		cwd = ctx.cwd,
		["entity-file-b64-src"] = ctx.entity_file_b64_src,
		["entity-file-path"] = ctx.entity_file_path,
		["field-name"] = field_config.field_name,
		["field-type"] = field_config.field_type,
		["field-id-generation"] = transform_id_generation(field_config.id_generation),
		["field-id-generation-type"] = transform_id_generation_type(field_config.id_generation_type),
	}

	-- Add optional field-type-package-name
	if field_config.field_package_path and field_config.field_package_path ~= "" then
		args["field-type-package-name"] = field_config.field_package_path
	end

	-- Add optional generator name
	if field_config.generator_name and field_config.generator_name ~= "" then
		args["field-generator-name"] = field_config.generator_name
	end

	-- Add optional sequence name
	if field_config.sequence_name and field_config.sequence_name ~= "" then
		args["field-sequence-name"] = field_config.sequence_name
	end

	-- Add optional numeric fields
	local initial_value = parse_number(field_config.initial_value)
	if initial_value then
		args["field-initial-value"] = initial_value
	end

	local allocation_size = parse_number(field_config.allocation_size)
	if allocation_size then
		args["field-allocation-size"] = allocation_size
	end

	-- Note: field-nullable is INVERTED from mandatory
	if not is_mandatory then
		args["field-nullable"] = true
	end

	-- Execute command
	command_runner.execute("create-jpa-entity-id-field", args, callback, options)
end

return M
