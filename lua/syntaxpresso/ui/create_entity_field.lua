local n = require("nui-components")
local basic_field = require("syntaxpresso.ui.create_basic_field")
local enum_field = require("syntaxpresso.ui.create_enum_field")
local id_field = require("syntaxpresso.ui.create_id_field")
local select_one = require("syntaxpresso.ui.components.select_one")
local text = require("syntaxpresso.ui.components.text")

local M = {}

local renderer = n.create_renderer({ height = 7 })

-- Function to create fresh node instances for field categories
local function create_field_category_data()
	return {
		n.node({ text = "Basic Field", is_done = true, id = "basic" }),
		n.node({ text = "Enum Field", is_done = false, id = "enum" }),
		n.node({ text = "ID Field", is_done = false, id = "id" }),
	}
end

local DEFAULT_SIGNAL_VALUES = {
	field_category = "basic",
	next_button_hidden = false,
	previous_button_hidden = true,
	confirm_button_hidden = true,
	field_category_data = create_field_category_data(),
}

---@class EntityFieldDataSources
---@field basic_types table[]
---@field id_types table[]
---@field types_with_length table[]
---@field types_with_time_zone_storage table[]
---@field types_with_temporal table[]
---@field types_with_extra_other table[]
---@field types_with_precision_and_scale table[]
---@field enum_files table[]
---@field entity_info table
---@field source_bufnr number
---@type EntityFieldDataSources|nil
local data_sources = nil

local signal = n.create_signal()

local function reset_signal()
	-- Reset primitive values
	signal.field_category = DEFAULT_SIGNAL_VALUES.field_category
	signal.next_button_hidden = DEFAULT_SIGNAL_VALUES.next_button_hidden
	signal.previous_button_hidden = DEFAULT_SIGNAL_VALUES.previous_button_hidden
	signal.confirm_button_hidden = DEFAULT_SIGNAL_VALUES.confirm_button_hidden
	signal.field_category_data = create_field_category_data()
end

local function create_previous_button(child_renderer)
	return n.button({
		flex = 1,
		label = "Previous <-",
		align = "center",
		on_press = function()
			reset_signal()
			child_renderer:close() -- Close child renderer first
			renderer:close() -- Then close parent renderer
			renderer:render(M.render_field_category_selection())
		end,
		hidden = false,
	})
end

local function render_next_button(_signal)
	return n.button({
		flex = 1,
		label = "Next ->",
		align = "center",
		global_press_key = "<C-CR>",
		on_press = function()
			if not data_sources then
				vim.notify("Data sources not loaded", vim.log.levels.ERROR)
				return
			end
			renderer:close()
			if _signal.field_category:get_value() == "basic" then
				basic_field.render(create_previous_button, {
					basic_types = data_sources.basic_types,
					types_with_length = data_sources.types_with_length,
					types_with_time_zone_storage = data_sources.types_with_time_zone_storage,
					types_with_temporal = data_sources.types_with_temporal,
					types_with_extra_other = data_sources.types_with_extra_other,
					types_with_precision_and_scale = data_sources.types_with_precision_and_scale,
				}, data_sources.source_bufnr)
			elseif _signal.field_category:get_value() == "enum" then
				enum_field.render(create_previous_button, data_sources.enum_files, data_sources.source_bufnr)
			elseif _signal.field_category:get_value() == "id" then
				id_field.render(
					create_previous_button,
					data_sources.id_types,
					data_sources.entity_info,
					data_sources.source_bufnr
				)
			end
			_signal.next_button_hidden = true
			_signal.confirm_button_hidden = false
			_signal.previous_button_hidden = false
		end,
		hidden = _signal.next_button_hidden,
	})
end

function M.render_field_category_selection()
	return n.tabs(
		{ active_tab = signal.active_tab },
		text.render_component({ text = "New Entity field" }),
		select_one.render_component({
			label = "Category",
			data = signal.field_category_data,
			signal = signal,
			signal_key = "field_category",
			signal_hidden_key = nil,
			autofocus = true,
			size = 3,
		}),
		n.columns({ flex = 0 }, render_next_button(signal))
	)
end

function M.render(_data_sources)
	data_sources = _data_sources
	reset_signal()
	renderer:render(M.render_field_category_selection())
end

return M
