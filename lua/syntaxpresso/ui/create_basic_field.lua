local n = require("nui-components")
local select_one = require("syntaxpresso.ui.components.select_one")
local select_many = require("syntaxpresso.ui.components.select_many")
local text_input = require("syntaxpresso.ui.components.text_input")
local text = require("syntaxpresso.ui.components.text")
local create_jpa_entity_basic_field = require("syntaxpresso.commands.create_jpa_entity_basic_field")

local M = {}

local signal = n.create_signal({
	field_package_path = "java.lang",
	field_type = "String",
	field_name = "",
	field_length = "255",
	other = {},
	field_precision = "19",
	field_scale = "2",
	field_time_zone_storage = "",
	field_temporal = "",
	field_length_hidden = false,
	field_temporal_hidden = true,
	field_time_zone_storage_hidden = true,
	field_scale_hidden = true,
	field_precision_hidden = true,
	other_extra_hidden = false,
	other_hidden = true,
	all_types = {},
	types_with_length = {},
	types_with_time_zone_storage = {},
	types_with_temporal = {},
	types_with_extra_other = {},
	types_with_precision_and_scale = {},
})

local renderer = n.create_renderer()

local time_zone_storage_data = {
	n.node({ text = "NATIVE", is_done = false, id = "NATIVE" }),
	n.node({ text = "NORMALIZE", is_done = false, id = "NORMALIZE" }),
	n.node({ text = "NORMALIZE_UTC", is_done = false, id = "NORMALIZE_UTC" }),
	n.node({ text = "COLUMN", is_done = false, id = "COLUMN" }),
	n.node({ text = "AUTO", is_done = false, id = "AUTO" }),
}

local field_temporal_data = {
	n.node({ text = "DATE", is_done = false, id = "DATE" }),
	n.node({ text = "TIME", is_done = false, id = "TIME" }),
	n.node({ text = "TIMESTAMP", is_done = false, id = "TIMESTAMP" }),
}

local other_data = {
	n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
	n.node({ text = "Unique", is_done = false, id = "unique" }),
}

local other_extra_data = {
	n.node({ text = "Large object", is_done = false, id = "large_object" }),
	n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
	n.node({ text = "Unique", is_done = false, id = "unique" }),
}

local function process_type_data(type_data)
	local all_types = {}
	local types_with_length = {}
	local types_with_time_zone_storage = {}
	local types_with_temporal = {}
	local types_with_extra_other = {}
	local types_with_precision_and_scale = {}
	local is_done = false
	for _, v in ipairs(type_data.basic_types) do
		if v.id == "java.lang.String" then
			is_done = true
		end
		table.insert(
			all_types,
			n.node({
				id = v.id,
				package_path = v.packagePath,
				text = v.name .. " (" .. tostring(v.packagePath) .. ")",
				name = v.name,
				is_done = is_done,
			})
		)
		is_done = false
	end
	for _, v in ipairs(type_data.types_with_length) do
		table.insert(types_with_length, v.id)
	end
	for _, v in ipairs(type_data.types_with_extra_other) do
		table.insert(types_with_extra_other, v.id)
	end
	for _, v in ipairs(type_data.types_with_precision_and_scale) do
		table.insert(types_with_precision_and_scale, v.id)
	end
	for _, v in ipairs(type_data.types_with_temporal) do
		table.insert(types_with_temporal, v.id)
	end
	for _, v in ipairs(type_data.types_with_time_zone_storage) do
		table.insert(types_with_time_zone_storage, v.id)
		types_with_time_zone_storage[v.id] = true
	end
	signal.all_types = all_types
	signal.types_with_length = types_with_length
	signal.types_with_extra_other = types_with_extra_other
	signal.types_with_precision_and_scale = types_with_precision_and_scale
	signal.types_with_temporal = types_with_temporal
	signal.types_with_time_zone_storage = types_with_time_zone_storage
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

			local time_zone_storage = get_signal_value(signal.field_time_zone_storage)
			local temporal = get_signal_value(signal.field_temporal)

			local field_config = {
				field_package_path = get_signal_value(signal.field_package_path),
				field_type = get_signal_value(signal.field_type),
				field_name = get_signal_value(signal.field_name),
				field_length = get_signal_value(signal.field_length),
				field_precision = get_signal_value(signal.field_precision),
				field_scale = get_signal_value(signal.field_scale),
				field_time_zone_storage = (time_zone_storage ~= "" and time_zone_storage or nil),
				field_temporal = (temporal ~= "" and temporal or nil),
				other = get_signal_value(signal.other),
			}

			-- Close UI
			renderer:close()

			-- Call command with callback (entity context captured inside the command)
			create_jpa_entity_basic_field.create_jpa_entity_basic_field(field_config, function(response, error)
				if error then
					vim.notify("Failed to create field: " .. error, vim.log.levels.ERROR)
					return
				end

				if response then
					vim.notify("Field created successfully!", vim.log.levels.INFO)
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
		text.render_component({ text = "New basic attribute" }),
		select_one.render_component({
			label = "Field type",
			data = signal.all_types,
			signal = signal,
			signal_key = "field_type",
			signal_hidden_key = nil,
			autofocus = true,
			size = 10,
			on_select_callback = function(_, node, _)
				signal.field_package_path = node.package_path
				signal.field_type = node.name
				if signal.types_with_length[node.id] then
					signal.field_length_hidden = false
				else
					signal.field_length_hidden = true
				end
				if signal.types_with_time_zone_storage[node.id] then
					signal.field_time_zone_storage_hidden = false
				else
					signal.field_time_zone_storage_hidden = true
				end
				if signal.types_with_temporal[node.id] then
					signal.field_temporal_hidden = false
				else
					signal.field_temporal_hidden = true
				end
				if signal.types_with_extra_other[node.id] then
					signal.other_hidden = true
					signal.other_extra_hidden = false
				else
					signal.other_hidden = false
					signal.other_extra_hidden = true
				end
				if signal.types_with_precision_and_scale[node.id] then
					signal.field_scale_hidden = false
					signal.field_precision_hidden = false
				else
					signal.field_scale_hidden = true
					signal.field_precision_hidden = true
				end
			end,
		}),
		text_input.render_component({
			title = "Field name",
			signal = signal,
			signal_key = "field_name",
			size = 1,
		}),
		text_input.render_component({
			title = "Field length",
			signal = signal,
			signal_key = "field_length",
			signal_hidden_key = "field_length_hidden",
			size = 1,
		}),
		select_one.render_component({
			label = "Time Zone Storage",
			data = time_zone_storage_data,
			signal = signal,
			signal_key = "field_time_zone_storage",
			signal_hidden_key = "field_time_zone_storage_hidden",
		}),
		select_one.render_component({
			label = "Temporal",
			data = field_temporal_data,
			signal = signal,
			signal_key = "field_temporal",
			signal_hidden_key = "field_temporal_hidden",
		}),
		n.columns(
			{ flex = 0, hidden = signal.field_precision_hidden and signal.field_scale_hidden },
			text_input.render_component({
				title = "Field precision",
				signal = signal,
				signal_key = "field_precision",
				signal_hidden_key = "field_precision_hidden",
				flex = 1,
				size = 1,
			}),
			text_input.render_component({
				title = "Field scale",
				signal = signal,
				signal_key = "field_scale",
				signal_hidden_key = "field_scale_hidden",
				flex = 1,
				size = 1,
			})
		),
		select_many.render_component({
			title = "Other",
			data = other_data,
			signal = signal,
			signal_key = "other",
			signal_hidden_key = "other_hidden",
		}),
		select_many.render_component({
			title = "Other",
			data = other_extra_data,
			signal = signal,
			signal_key = "other",
			signal_hidden_key = "other_extra_hidden",
		}),
		n.gap(1),
		n.columns(_previous_button_fn(renderer), render_confirm_button())
	)
end

function M.render(_previous_button_fn, type_data)
	process_type_data(type_data)
	renderer:render(render_component(_previous_button_fn))
end

return M
