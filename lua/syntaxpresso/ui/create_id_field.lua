local n = require("nui-components")
local select_one = require("syntaxpresso.ui.components.select_one")
local select_many = require("syntaxpresso.ui.components.select_many")
local text_input = require("syntaxpresso.ui.components.text_input")
local text = require("syntaxpresso.ui.components.text")
local create_jpa_entity_id_field = require("syntaxpresso.commands.create_jpa_entity_id_field")

local M = {}

local renderer = n.create_renderer()

-- Declare and initialize signal at module level so callbacks can access it
local signal = n.create_signal({
	field_package_path = "java.lang",
	field_type = "Long",
	field_name = "id",
	id_generation = "auto",
	id_generation_type = "none",
	generator_name = "",
	sequence_name = "",
	initial_value = "1",
	allocation_size = "50",
	id_generation_hidden = false,
	id_generation_type_hidden = true,
	generator_name_hidden = true,
	sequence_name_hidden = true,
	initial_value_hidden = true,
	allocation_size_hidden = true,
	other = { "mandatory" },
	all_id_types = {},
})

-- ID Generation options for numeric types
local numeric_id_generation_data = {
	n.node({ text = "None (Manual)", is_done = false, id = "none" }),
	n.node({ text = "Auto", is_done = true, id = "auto" }),
	n.node({ text = "Identity", is_done = false, id = "identity" }),
	n.node({ text = "Sequence", is_done = false, id = "sequence" }),
}

-- Generation type options (only for SEQUENCE)
local generation_type_data = {
	n.node({ text = "ORM Provided", is_done = true, id = "orm_provided" }),
	n.node({ text = "Entity Exclusive Generation", is_done = false, id = "entity_exclusive_generation" }),
}

local other_data = {
	n.node({ text = "Mandatory", is_done = true, id = "mandatory" }),
	n.node({ text = "Mutable", is_done = false, id = "mutable" }),
}

local function process_entity_info(entity_info)
	if entity_info and entity_info.entityTableName ~= nil then
		signal.generator_name = entity_info.entityTableName .. "_gen"
		signal.sequence_name = entity_info.entityTableName .. "_seq"
	elseif entity_info and entity_info.entityType and #entity_info.entityType > 0 then
		local camel_case_type = string.lower(string.sub(entity_info.entityType, 1, 1))
			.. string.sub(entity_info.entityType, 2)
		signal.generator_name = camel_case_type .. "_gen"
		signal.sequence_name = camel_case_type .. "_seq"
	end
end

local function process_id_types(_id_types)
	local all_id_types = {}
	if not _id_types or #_id_types == 0 then
		-- Return placeholder when no id types are available
		table.insert(all_id_types, n.node({ text = "Loading...", is_done = false, id = "loading" }))
		signal.all_id_types = all_id_types
		return
	end
	for _, v in ipairs(_id_types) do
		local is_done = false
		if v.id == "java.lang.Long" then
			is_done = true
		end
		table.insert(
			all_id_types,
			n.node({
				id = v.id,
				package_path = v.packagePath,
				text = v.name .. " (" .. tostring(v.packagePath) .. ")",
				name = v.name,
				is_done = is_done,
			})
		)
	end
	signal.all_id_types = all_id_types
end

-- Update UI visibility based on field type selection
local function on_field_type_select(_, node, _)
	signal.field_type = node.name
	signal.field_package_path = node.package_path

	-- Rule: UUID type can ONLY use uuid generation
	if node.name == "UUID" then
		signal.id_generation = "uuid"
		signal.id_generation_hidden = true
		signal.id_generation_type_hidden = true
		signal.generator_name_hidden = true
		signal.sequence_name_hidden = true
		signal.initial_value_hidden = true
		signal.allocation_size_hidden = true
	else
		-- Numeric types: show generation options, default to auto
		signal.id_generation = "auto"
		signal.id_generation_hidden = false
		signal.id_generation_type_hidden = true
		signal.generator_name_hidden = true
		signal.sequence_name_hidden = true
		signal.initial_value_hidden = true
		signal.allocation_size_hidden = true
	end
end

-- Update UI visibility based on ID generation strategy selection
local function on_id_generation_select(_, node, _)
	signal.id_generation = node.id

	-- Rule: Only SEQUENCE generation uses generation type and related fields
	if node.id == "sequence" then
		signal.id_generation_type_hidden = false
		signal.id_generation_type = "orm_provided"
		-- Initially hide sequence-specific fields (shown when entity_exclusive is selected)
		signal.generator_name_hidden = true
		signal.sequence_name_hidden = true
		signal.initial_value_hidden = true
		signal.allocation_size_hidden = true
	else
		-- none, auto, identity: hide all sequence-related fields
		signal.id_generation_type_hidden = true
		signal.generator_name_hidden = true
		signal.sequence_name_hidden = true
		signal.initial_value_hidden = true
		signal.allocation_size_hidden = true
	end
end

-- Update UI visibility based on generation type selection
local function on_generation_type_select(_, node, _)
	signal.id_generation_type = node.id

	-- Rule: Only entity_exclusive_generation requires generator/sequence configuration
	if node.id == "entity_exclusive_generation" then
		signal.generator_name_hidden = false
		signal.sequence_name_hidden = false
		signal.initial_value_hidden = false
		signal.allocation_size_hidden = false
	else
		-- orm_provided: hide all custom generator fields
		signal.generator_name_hidden = true
		signal.sequence_name_hidden = true
		signal.initial_value_hidden = true
		signal.allocation_size_hidden = true
	end
end

local function render_confirm_button()
	return n.button({
		flex = 1,
		label = "Confirm",
		align = "center",
		global_press_key = "<C-CR>",
		on_press = function()
			-- Prepare field configuration
			local function get_signal_value(value)
				if type(value) == "table" and value.get_value then
					return value:get_value()
				end
				return value
			end

			local id_generation = get_signal_value(signal.id_generation)
			local id_generation_type = get_signal_value(signal.id_generation_type)
			local generator_name = get_signal_value(signal.generator_name)
			local sequence_name = get_signal_value(signal.sequence_name)

			-- Validation: entity_exclusive_generation requires generator_name (sequence_name is optional)
			if
				id_generation == "sequence"
				and id_generation_type == "entity_exclusive_generation"
				and (not generator_name or generator_name == "")
			then
				vim.notify("Error: Generator name is required for entity exclusive generation", vim.log.levels.ERROR)
				return
			end

			local field_config = {
				field_package_path = get_signal_value(signal.field_package_path),
				field_type = get_signal_value(signal.field_type),
				field_name = get_signal_value(signal.field_name),
				id_generation = id_generation,
				id_generation_type = id_generation_type,
				generator_name = generator_name,
				sequence_name = sequence_name,
				initial_value = get_signal_value(signal.initial_value),
				allocation_size = get_signal_value(signal.allocation_size),
				other = get_signal_value(signal.other),
			}

			-- Close UI
			renderer:close()

			-- Call command with callback
			create_jpa_entity_id_field.create_jpa_entity_id_field(field_config, function(response, error)
				if error then
					vim.notify("Failed to create ID field: " .. error, vim.log.levels.ERROR)
					return
				end

				if response then
					vim.notify("ID field created successfully!", vim.log.levels.INFO)
					-- Reload buffer to show changes
					vim.schedule(function()
						vim.cmd("checktime")
					end)
				end
			end, nil)
		end,
		hidden = signal.confirm_btn_hidden,
	})
end

local function render_component(_previous_button_fn)
	return n.rows(
		{ flex = 0 },
		text.render_component({ text = "New Entity field" }),
		text.render_component({ text = "New ID attribute" }),
		select_one.render_component({
			label = "Field type",
			data = signal.all_id_types,
			signal = signal,
			signal_key = "field_type",
			autofocus = true,
			size = 4,
			on_select_callback = on_field_type_select,
		}),
		text_input.render_component({
			title = "Field name",
			signal = signal,
			signal_key = "field_name",
			size = 1,
		}),
		select_one.render_component({
			label = "ID Generation Strategy",
			data = numeric_id_generation_data,
			signal = signal,
			signal_key = "id_generation",
			signal_hidden_key = "id_generation_hidden",
			on_select_callback = on_id_generation_select,
		}),
		select_one.render_component({
			label = "Generation Type",
			data = generation_type_data,
			signal = signal,
			signal_key = "id_generation_type",
			signal_hidden_key = "id_generation_type_hidden",
			on_select_callback = on_generation_type_select,
		}),
		text_input.render_component({
			title = "Generator name (required)",
			signal = signal,
			signal_key = "generator_name",
			signal_hidden_key = "generator_name_hidden",
			size = 1,
		}),
		text_input.render_component({
			title = "Sequence name (optional - uses provider default if empty)",
			signal = signal,
			signal_key = "sequence_name",
			signal_hidden_key = "sequence_name_hidden",
			size = 1,
		}),
		text_input.render_component({
			title = "Initial value (default: 1)",
			signal = signal,
			signal_key = "initial_value",
			signal_hidden_key = "initial_value_hidden",
			size = 1,
		}),
		text_input.render_component({
			title = "Allocation size (default: 50)",
			signal = signal,
			signal_key = "allocation_size",
			signal_hidden_key = "allocation_size_hidden",
			size = 1,
		}),
		select_many.render_component({
			title = "Other",
			data = other_data,
			signal = signal,
			signal_key = "other",
		}),
		n.gap(1),
		n.columns(_previous_button_fn(renderer), render_confirm_button())
	)
end

function M.render(_previous_button_fn, _id_types, _entity_info)
	-- Reset signal to defaults
	signal.field_package_path = "java.lang"
	signal.field_type = "Long"
	signal.field_name = "id"
	signal.id_generation = "auto"
	signal.id_generation_type = "orm_provided"
	signal.initial_value = "1"
	signal.allocation_size = "50"
	signal.id_generation_hidden = false
	signal.id_generation_type_hidden = true
	signal.generator_name_hidden = true
	signal.sequence_name_hidden = true
	signal.initial_value_hidden = true
	signal.allocation_size_hidden = true
	signal.other = { "mandatory" }

	process_entity_info(_entity_info)
	process_id_types(_id_types)
	renderer:render(render_component(_previous_button_fn))
end

return M
