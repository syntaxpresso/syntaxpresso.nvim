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
	generator_name = "gen__gen",
	sequence_name = "gen__seq",
	initial_value = "1",
	allocation_size = "50",
	regular_id_generation_type_hidden = false,
	uuid_id_generation_type_hidden = true,
	generator_name_hidden = true,
	sequence_name_hidden = true,
	initial_value_hidden = true,
	allocation_size_hidden = true,
	other = { "mandatory" },
	all_id_types = {},
})

local uuid_id_generation_type_data = {
	n.node({ text = "None", is_done = false, id = "none" }),
	n.node({ text = "Auto", is_done = false, id = "auto" }),
	n.node({ text = "UUID", is_done = true, id = "uuid" }),
}

local regular_id_generation_type_data = {
	n.node({ text = "None", is_done = false, id = "none" }),
	n.node({ text = "Auto", is_done = true, id = "auto" }),
	n.node({ text = "Identity", is_done = false, id = "identity" }),
	n.node({ text = "Sequence", is_done = false, id = "sequence" }),
}

local generation_type_data = {
	n.node({ text = "None", is_done = true, id = "none" }),
	n.node({ text = "Generate exclusively for entity", is_done = false, id = "entity_exclusive_generation" }),
	n.node({ text = "Provided by ORM", is_done = false, id = "orm_provided" }),
}

local other_data = {
	n.node({ text = "Mandatory", is_done = true, id = "mandatory" }),
	n.node({ text = "Mutable", is_done = false, id = "mutable" }),
}

local function process_entity_info(entity_info)
	if entity_info and entity_info.entityTableName ~= nil then
		signal.generator_name = entity_info.entityTableName .. "_gen"
		signal.sequence_name = entity_info.entityTableName .. "_seq"
	else
		if entity_info and entity_info.entityType and #entity_info.entityType > 0 then
			local camel_case_type = string.lower(string.sub(entity_info.entityType, 1, 1))
				.. string.sub(entity_info.entityType, 2)
			signal.generator_name = camel_case_type .. "__gen"
			signal.sequence_name = camel_case_type .. "__seq"
		end
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

local function id_generation_callback(_signal, _selected_node, _)
	if _selected_node.id == "sequence" then
		_signal.id_generation_type_hidden = false
	else
		_signal.id_generation_type_hidden = true
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

			local field_config = {
				field_package_path = get_signal_value(signal.field_package_path),
				field_type = get_signal_value(signal.field_type),
				field_name = get_signal_value(signal.field_name),
				id_generation = get_signal_value(signal.id_generation),
				id_generation_type = get_signal_value(signal.id_generation_type),
				generator_name = get_signal_value(signal.generator_name),
				sequence_name = get_signal_value(signal.sequence_name),
				initial_value = get_signal_value(signal.initial_value),
				allocation_size = get_signal_value(signal.allocation_size),
				other = get_signal_value(signal.other),
			}

			-- Close UI
			renderer:close()

			-- Call command with callback (context captured from source buffer)
			create_jpa_entity_id_field.create_jpa_entity_id_field(field_config, function(response, error)
				if error then
					vim.notify("Failed to create ID field: " .. error, vim.log.levels.ERROR)
					return
				end

				if response then
					vim.notify("ID field created successfully!", vim.log.levels.INFO)
					-- Reload buffer to show changes (use vim.schedule to avoid fast event context error)
					vim.schedule(function()
						vim.cmd("checktime")
					end)
				end
			end, nil)
		end,
		hidden = signal.confirm_btn_hidden,
	})
end

local function render_component(_previous_button_fn, entity_info)
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
			on_select_callback = function(_, node, _)
				signal.field_type = node.type
				signal.field_package_path = node.package_path
				if node.name == "UUID" then
					signal.uuid_id_generation_type_hidden = false
					signal.regular_id_generation_type_hidden = true
					signal.id_generation = "uuid"
				else
					signal.uuid_id_generation_type_hidden = true
					signal.regular_id_generation_type_hidden = false
					signal.id_generation = "auto"
				end
			end,
		}),
		text_input.render_component({
			title = "Field name",
			signal = signal,
			signal_key = "field_name",
			size = 1,
		}),
		select_one.render_component({
			label = "Id generation",
			data = regular_id_generation_type_data,
			signal = signal,
			signal_key = "id_generation",
			signal_hidden_key = "regular_id_generation_type_hidden",
		}),
		select_one.render_component({
			label = "Id generation",
			data = uuid_id_generation_type_data,
			signal = signal,
			signal_key = "id_generation",
			signal_hidden_key = "uuid_id_generation_type_hidden",
			on_select_callback = id_generation_callback,
		}),
		select_one.render_component({
			label = "Generation type",
			data = generation_type_data,
			signal = signal,
			signal_key = "id_generation_type",
			on_select_callback = function(_, node, _)
				vim.notify(vim.inspect(node), vim.log.levels.INFO)
				vim.notify(vim.inspect(entity_info), vim.log.levels.INFO)
				if node.id == "entity_exclusive_generation" then
					signal["generator_name_hidden"] = false
					signal["sequence_name_hidden"] = false
					signal["initial_value_hidden"] = false
					signal["allocation_size_hidden"] = false
				else
					signal["generator_name_hidden"] = true
					signal["sequence_name_hidden"] = true
					signal["initial_value_hidden"] = true
					signal["allocation_size_hidden"] = true
				end
			end,
		}),
		text_input.render_component({
			title = "Generator name",
			signal = signal,
			signal_key = "generator_name",
			signal_hidden_key = "generator_name_hidden",
			size = 1,
		}),
		text_input.render_component({
			title = "Sequence name",
			signal = signal,
			signal_key = "sequence_name",
			signal_hidden_key = "sequence_name_hidden",
			size = 1,
		}),
		text_input.render_component({
			title = "Initial value",
			signal = signal,
			signal_key = "initial_value",
			signal_hidden_key = "initial_value_hidden",
			size = 1,
		}),
		text_input.render_component({
			title = "Allocation size",
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
	process_entity_info(_entity_info)
	process_id_types(_id_types)
	renderer:render(render_component(_previous_button_fn, _entity_info))
end

return M
