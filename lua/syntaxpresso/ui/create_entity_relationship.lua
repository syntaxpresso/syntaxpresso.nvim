local n = require("nui-components")
local one_to_one = require("syntaxpresso.ui.create_one_to_one_relationship")
local many_to_one = require("syntaxpresso.ui.create_many_to_one_relationship")
local select_one = require("syntaxpresso.ui.components.select_one")
local text = require("syntaxpresso.ui.components.text")

local M = {}

local renderer = n.create_renderer({ height = 7 })

-- Function to create fresh node instances for relationship categories
local function create_relationship_category_data()
	return {
		n.node({ text = "One-to-One", is_done = true, id = "one_to_one" }),
		n.node({ text = "Many-to-One", is_done = false, id = "many_to_one" }),
		n.node({ text = "One-to-Many (Coming Soon)", is_done = false, id = "one_to_many" }),
		n.node({ text = "Many-to-Many (Coming Soon)", is_done = false, id = "many_to_many" }),
	}
end

local DEFAULT_SIGNAL_VALUES = {
	relationship_category = "one_to_one",
	next_button_hidden = false,
	previous_button_hidden = true,
	confirm_button_hidden = true,
	relationship_category_data = create_relationship_category_data(),
}

---@class EntityRelationshipDataSources
---@field entity_files table[]
---@field entity_info table
---@field source_bufnr number
---@type EntityRelationshipDataSources|nil
local data_sources = nil

local signal = n.create_signal()

local function reset_signal()
	-- Reset primitive values
	signal.relationship_category = DEFAULT_SIGNAL_VALUES.relationship_category
	signal.next_button_hidden = DEFAULT_SIGNAL_VALUES.next_button_hidden
	signal.previous_button_hidden = DEFAULT_SIGNAL_VALUES.previous_button_hidden
	signal.confirm_button_hidden = DEFAULT_SIGNAL_VALUES.confirm_button_hidden
	signal.relationship_category_data = create_relationship_category_data()
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
			renderer:render(M.render_relationship_category_selection())
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
			local rel_type = _signal.relationship_category:get_value()
			if rel_type == "one_to_one" then
				one_to_one.render(create_previous_button, data_sources.entity_files)
			elseif rel_type == "many_to_one" then
				many_to_one.render(create_previous_button, data_sources.entity_files)
			else
				vim.notify("This relationship type is not yet implemented", vim.log.levels.WARN)
			end
			_signal.next_button_hidden = true
			_signal.confirm_button_hidden = false
			_signal.previous_button_hidden = false
		end,
		hidden = _signal.next_button_hidden,
	})
end

function M.render_relationship_category_selection()
	return n.tabs(
		{ active_tab = signal.active_tab },
		text.render_component({ text = "New Entity Relationship" }),
		select_one.render_component({
			label = "Relationship Type",
			data = signal.relationship_category_data,
			signal = signal,
			signal_key = "relationship_category",
			signal_hidden_key = nil,
			autofocus = true,
			size = 4,
		}),
		n.columns({ flex = 0 }, render_next_button(signal))
	)
end

function M.render(_data_sources)
	data_sources = _data_sources
	reset_signal()
	renderer:render(M.render_relationship_category_selection())
end

return M
