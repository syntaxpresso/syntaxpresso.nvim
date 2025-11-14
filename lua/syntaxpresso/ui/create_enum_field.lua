local n = require("nui-components")
local select_one = require("syntaxpresso.ui.components.select_one")
local select_many = require("syntaxpresso.ui.components.select_many")
local text_input = require("syntaxpresso.ui.components.text_input")
local text = require("syntaxpresso.ui.components.text")
local create_jpa_entity_enum_field = require("syntaxpresso.commands.create_jpa_entity_enum_field")

local M = {}

local signal = n.create_signal({
	field_path = nil,
	field_type = nil,
	field_name = "",
	field_package_path = nil,
	enum_type_storage = "STRING",
	field_length = "255",
	field_length_hidden = true,
	other = {},
	all_enum_types = {},
})

local renderer = n.create_renderer()

local enum_type_storage_data = {
	n.node({ text = "ORDINAL", is_done = false, id = "ORDINAL" }),
	n.node({ text = "STRING", is_done = true, id = "STRING" }),
}

local other_data = {
	n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
	n.node({ text = "Unique", is_done = false, id = "unique" }),
}

local function auto_field_name(type_name)
	-- Convert CamelCase to camelCase for field name
	if type_name and #type_name > 0 then
		return string.lower(string.sub(type_name, 1, 1)) .. string.sub(type_name, 2)
	end
	return ""
end

local function process_enum_files(_enum_files)
	local all_enum_types = {}

	-- Extract files array from response object
	local files = _enum_files and _enum_files.data and _enum_files.data.files or nil

	if not files or #files == 0 then
		-- Return placeholder when no enum options are available
		vim.notify("No enum files found or empty array", vim.log.levels.WARN)
		table.insert(all_enum_types, n.node({ text = "No enums found", is_done = false, id = "no_enums" }))
		signal.all_enum_types = all_enum_types
		return
	end

	for _, v in ipairs(files) do
		table.insert(
			all_enum_types,
			n.node({
				text = v.fileType .. " (" .. v.filePackageName .. ")",
				type = v.fileType,
				package_path = v.filePackageName,
				is_done = false,
				id = v.filePath,
			})
		)
	end
	signal.all_enum_types = all_enum_types
end

local function field_type_callback(_signal, _selected_node, _)
	_signal["field_path"] = _selected_node.id
	_signal["field_type"] = _selected_node.type
	_signal["field_package_path"] = _selected_node.package_path
	_signal["field_name"] = auto_field_name(_selected_node.type)
end

local function enum_type_storage_callback(_signal, _selected_node, _)
	if _selected_node.id == "STRING" then
		_signal.field_length_hidden = false
	else
		_signal.field_length_hidden = true
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
			-- Safely get values - handle both signal objects and plain values
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
				enum_type_storage = get_signal_value(signal.enum_type_storage),
				field_length = get_signal_value(signal.field_length),
				other = get_signal_value(signal.other),
			}

			-- Close UI
			renderer:close()

			-- Call command with callback (context captured from source buffer)
			create_jpa_entity_enum_field.create_jpa_entity_enum_field(field_config, function(response, error)
				if error then
					vim.notify("Failed to create enum field: " .. error, vim.log.levels.ERROR)
					return
				end

				if response then
					vim.notify("Enum field created successfully!", vim.log.levels.INFO)
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

local function render_component(_previous_button_fn)
	return n.rows(
		{ flex = 0 },
		text.render_component({ text = "New Entity field" }),
		text.render_component({ text = "New Enum attribute" }),
		select_one.render_component({
			label = "Field type",
			data = signal.all_enum_types,
			signal = signal,
			signal_key = "field_type",
			autofocus = true,
			size = 7,
			on_select_callback = field_type_callback,
		}),
		select_one.render_component({
			label = "Enum type storage",
			data = enum_type_storage_data,
			signal = signal,
			signal_key = "enum_type_storage",
			on_select_callback = enum_type_storage_callback,
		}),
		text_input.render_component({
			title = "Field name",
			signal = signal,
			signal_key = "field_name",
			signal_hidden_key = "field_name_hidden",
			size = 1,
		}),
		text_input.render_component({
			title = "Field length",
			signal = signal,
			signal_key = "field_length",
			signal_hidden_key = "field_length_hidden",
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

function M.render(_previous_button_fn, _enum_files)
	process_enum_files(_enum_files)
	renderer:render(render_component(_previous_button_fn))
end

return M
