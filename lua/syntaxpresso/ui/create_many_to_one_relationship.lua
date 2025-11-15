local n = require("nui-components")
local select_one = require("syntaxpresso.ui.components.select_one")
local select_many = require("syntaxpresso.ui.components.select_many")
local text_input = require("syntaxpresso.ui.components.text_input")
local create_jpa_many_to_one_relationship = require("syntaxpresso.commands.create_jpa_many_to_one_relationship")

local M = {}

local renderer = n.create_renderer()

-- Factory functions to create fresh node instances
local function create_mapping_type_data()
	return {
		n.node({ text = "Bidirectional (Recommended)", is_done = true, id = "bidirectional_join_column" }),
		n.node({ text = "Unidirectional with Join Column", is_done = false, id = "unidirectional_join_column" }),
	}
end

local function create_cascade_data()
	return {
		n.node({ text = "PERSIST", is_done = false, id = "persist" }),
		n.node({ text = "MERGE", is_done = false, id = "merge" }),
		n.node({ text = "REMOVE", is_done = false, id = "remove" }),
		n.node({ text = "REFRESH", is_done = false, id = "refresh" }),
		n.node({ text = "DETACH", is_done = false, id = "detach" }),
	}
end

local function create_fetch_type_data()
	return {
		n.node({ text = "Lazy (Default)", is_done = true, id = "lazy" }),
		n.node({ text = "Eager", is_done = false, id = "eager" }),
	}
end

local function create_collection_type_data()
	return {
		n.node({ text = "List", is_done = true, id = "list" }),
		n.node({ text = "Set", is_done = false, id = "set" }),
		n.node({ text = "Collection", is_done = false, id = "collection" }),
	}
end

local function create_owning_side_other_data()
	return {
		n.node({ text = "Mandatory", is_done = false, id = "mandatory" }),
		n.node({ text = "Unique", is_done = false, id = "unique" }),
	}
end

local function create_inverse_side_other_data()
	return {
		n.node({ text = "Orphan Removal", is_done = false, id = "orphan_removal" }),
	}
end

local DEFAULT_SIGNAL_VALUES = {
	active_tab = "basic_config",
	confirm_btn_hidden = true,
	next_btn_hidden = false,
	owning_side_field_name = "",
	inverse_side_field_name = "",
	inverse_field_type = nil,
	mapping_type = "bidirectional_join_column",
	fetch_type = "lazy",
	collection_type = "list",
	owning_side_cascades = {},
	inverse_side_cascades = {},
	owning_side_other = {},
	inverse_side_other = {},
	all_entity_types = {},
	mapping_type_data = create_mapping_type_data(),
	fetch_type_data = create_fetch_type_data(),
	collection_type_data = create_collection_type_data(),
	owning_cascade_data = create_cascade_data(),
	inverse_cascade_data = create_cascade_data(),
	owning_side_other_data = create_owning_side_other_data(),
	inverse_side_other_data = create_inverse_side_other_data(),
}

local signal = n.create_signal()

local function reset_signal()
	-- Reset primitive values
	signal.active_tab = DEFAULT_SIGNAL_VALUES.active_tab
	signal.confirm_btn_hidden = DEFAULT_SIGNAL_VALUES.confirm_btn_hidden
	signal.next_btn_hidden = DEFAULT_SIGNAL_VALUES.next_btn_hidden
	signal.owning_side_field_name = DEFAULT_SIGNAL_VALUES.owning_side_field_name
	signal.inverse_side_field_name = DEFAULT_SIGNAL_VALUES.inverse_side_field_name
	signal.inverse_field_type = DEFAULT_SIGNAL_VALUES.inverse_field_type
	signal.mapping_type = DEFAULT_SIGNAL_VALUES.mapping_type
	signal.fetch_type = DEFAULT_SIGNAL_VALUES.fetch_type
	signal.collection_type = DEFAULT_SIGNAL_VALUES.collection_type
	signal.owning_side_cascades = DEFAULT_SIGNAL_VALUES.owning_side_cascades
	signal.inverse_side_cascades = DEFAULT_SIGNAL_VALUES.inverse_side_cascades
	signal.owning_side_other = DEFAULT_SIGNAL_VALUES.owning_side_other
	signal.inverse_side_other = DEFAULT_SIGNAL_VALUES.inverse_side_other
	signal.all_entity_types = DEFAULT_SIGNAL_VALUES.all_entity_types

	-- Create fresh node instances to avoid state pollution
	signal.mapping_type_data = create_mapping_type_data()
	signal.fetch_type_data = create_fetch_type_data()
	signal.collection_type_data = create_collection_type_data()
	signal.owning_cascade_data = create_cascade_data()
	signal.inverse_cascade_data = create_cascade_data()
	signal.owning_side_other_data = create_owning_side_other_data()
	signal.inverse_side_other_data = create_inverse_side_other_data()
end

local function process_entity_files(_entity_files)
	local all_entity_types = {}

	-- Extract files array from response object
	local files = _entity_files and _entity_files.data and _entity_files.data.files or nil

	if not files or #files == 0 then
		vim.notify("No entity files found", vim.log.levels.WARN)
		table.insert(all_entity_types, n.node({ text = "No entities found", is_done = false, id = "no_entities" }))
		signal.all_entity_types = all_entity_types
		return
	end

	for _, v in ipairs(files) do
		table.insert(
			all_entity_types,
			n.node({
				text = v.fileType .. " (" .. v.filePackageName .. ")",
				type = v.fileType,
				package_path = v.filePackageName,
				is_done = false,
				id = v.fileType,
			})
		)
	end
	signal.all_entity_types = all_entity_types
end

local function auto_field_name(type_name, pluralize)
	-- Convert CamelCase to camelCase for field name
	if type_name and #type_name > 0 then
		local base_name = string.lower(string.sub(type_name, 1, 1)) .. string.sub(type_name, 2)
		if pluralize then
			-- Simple pluralization: add 's' or 'es'
			if base_name:match("[sxz]$") or base_name:match("ch$") or base_name:match("sh$") then
				return base_name .. "es"
			else
				return base_name .. "s"
			end
		end
		return base_name
	end
	return ""
end

local function on_entity_type_select(_, node, _)
	signal.inverse_field_type = node.type
	signal.owning_side_field_name = auto_field_name(node.type, false)
	-- For inverse side (OneToMany), pluralize the field name
	signal.inverse_side_field_name = auto_field_name(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r"), true)
end

local function on_mapping_type_select(_, node, _)
	signal.mapping_type = node.id
	-- For unidirectional: hide Next, show Confirm on owning side tab
	-- For bidirectional: show Next, hide Confirm on owning side tab
	if node.id == "unidirectional_join_column" then
		signal.next_btn_hidden = true
		signal.confirm_btn_hidden = false
		signal.inverse_side_field_name = ""
		signal.inverse_side_cascades = {}
		signal.inverse_side_other = {}
	else
		signal.next_btn_hidden = false
		signal.confirm_btn_hidden = true
	end
end

local function render_main_title(subtitle)
	return n.rows(
		{ flex = 0 },
		n.paragraph({
			lines = {
				n.line(n.text("New Entity Relationship", "String")),
			},
			align = "center",
			is_focusable = false,
		}),
		n.paragraph({
			lines = {
				n.line(n.text(subtitle, "String")),
			},
			align = "center",
			is_focusable = false,
		})
	)
end

local function render_confirm_button()
	return n.button({
		flex = 1,
		label = "Confirm",
		align = "center",
		global_press_key = "<C-CR>",
		on_press = function()
			-- Prepare relationship configuration
			local function get_signal_value(value)
				if type(value) == "table" and value.get_value then
					return value:get_value()
				end
				return value
			end

			local owning_side_field_name = get_signal_value(signal.owning_side_field_name)
			local inverse_side_field_name = get_signal_value(signal.inverse_side_field_name)
			local inverse_field_type = get_signal_value(signal.inverse_field_type)
			local mapping_type = get_signal_value(signal.mapping_type)

			-- Validation
			if not inverse_field_type or inverse_field_type == "" then
				vim.notify("Error: Target entity type is required", vim.log.levels.ERROR)
				return
			end

			if not owning_side_field_name or owning_side_field_name == "" then
				vim.notify("Error: Owning side field name is required", vim.log.levels.ERROR)
				return
			end

			-- For bidirectional, inverse side field name is required
			if mapping_type == "bidirectional_join_column" then
				if not inverse_side_field_name or inverse_side_field_name == "" then
					vim.notify(
						"Error: Inverse side field name is required for bidirectional relationships",
						vim.log.levels.ERROR
					)
					return
				end
			else
				-- For unidirectional, set inverse field name to empty
				inverse_side_field_name = ""
			end

			local relationship_config = {
				owning_side_field_name = owning_side_field_name,
				inverse_side_field_name = inverse_side_field_name,
				inverse_field_type = inverse_field_type,
				mapping_type = mapping_type,
				fetch_type = get_signal_value(signal.fetch_type),
				collection_type = get_signal_value(signal.collection_type),
				owning_side_cascades = get_signal_value(signal.owning_side_cascades),
				inverse_side_cascades = get_signal_value(signal.inverse_side_cascades),
				owning_side_other = get_signal_value(signal.owning_side_other),
				inverse_side_other = get_signal_value(signal.inverse_side_other),
			}

			-- Close UI
			renderer:close()

			-- Call command with callback
			create_jpa_many_to_one_relationship.create_jpa_many_to_one_relationship(
				relationship_config,
				function(response, error)
					if error then
						vim.notify("Failed to create relationship: " .. error, vim.log.levels.ERROR)
						return
					end

					if response then
						vim.notify("Many-to-One relationship created successfully!", vim.log.levels.INFO)
						-- Reload buffer to show changes
						vim.schedule(function()
							vim.cmd("checktime")
						end)
					end
				end,
				nil
			)
			reset_signal()
		end,
		hidden = signal.confirm_btn_hidden,
	})
end

local function components(_previous_button_fn)
	return n.tabs(
		{ active_tab = signal.active_tab },
		-- Tab 1: Basic Configuration (ManyToOne/Owning Side)
		n.tab(
			{ id = "basic_config" },
			n.rows(
				{ flex = 0 },
				render_main_title("Many-to-One: Basic Configuration"),
				n.gap(1),
				select_one.render_component({
					label = "Mapping Type",
					data = signal.mapping_type_data,
					signal = signal,
					signal_key = "mapping_type",
					on_select_callback = on_mapping_type_select,
					autofocus = true,
					size = 2,
				}),
				select_one.render_component({
					label = "Target Entity Type (the 'One' side)",
					data = signal.all_entity_types,
					signal = signal,
					signal_key = "inverse_field_type",
					on_select_callback = on_entity_type_select,
					size = 7,
				}),
				text_input.render_component({
					title = "Owning Side Field Name (Many side)",
					signal = signal,
					signal_key = "owning_side_field_name",
					size = 1,
				}),
				text_input.render_component({
					title = "Inverse Side Field Name (One side, bidirectional only)",
					signal = signal,
					signal_key = "inverse_side_field_name",
					size = 1,
				}),
				select_one.render_component({
					label = "Fetch Type",
					data = signal.fetch_type_data,
					signal = signal,
					signal_key = "fetch_type",
					size = 2,
				}),
				select_many.render_component({
					title = "Owning Side Cascade Types",
					data = signal.owning_cascade_data,
					signal = signal,
					signal_key = "owning_side_cascades",
					size = 5,
				}),
				select_many.render_component({
					title = "Owning Side Options",
					data = signal.owning_side_other_data,
					signal = signal,
					signal_key = "owning_side_other",
					size = 2,
				}),
				n.gap(1),
				n.columns(
					{ flex = 0 },
					_previous_button_fn(renderer),
					n.button({
						flex = 1,
						label = "Next ->",
						align = "center",
						global_press_key = "<C-CR>",
						on_press = function()
							-- Validate before moving to next tab
							local function get_signal_value(value)
								if type(value) == "table" and value.get_value then
									return value:get_value()
								end
								return value
							end

							local inverse_field_type = get_signal_value(signal.inverse_field_type)
							local owning_side_field_name = get_signal_value(signal.owning_side_field_name)
							local inverse_side_field_name = get_signal_value(signal.inverse_side_field_name)

							if not inverse_field_type or inverse_field_type == "" then
								vim.notify("Error: Target entity type is required", vim.log.levels.ERROR)
								return
							end

							if not owning_side_field_name or owning_side_field_name == "" then
								vim.notify("Error: Owning side field name is required", vim.log.levels.ERROR)
								return
							end

							if not inverse_side_field_name or inverse_side_field_name == "" then
								vim.notify(
									"Error: Inverse side field name is required for bidirectional relationships",
									vim.log.levels.ERROR
								)
								return
							end

							signal.active_tab = "inverse_config"
							signal.confirm_btn_hidden = false
						end,
						hidden = signal.next_btn_hidden,
					}),
					render_confirm_button()
				)
			)
		),
		-- Tab 2: Inverse Side Configuration (OneToMany side, only for bidirectional)
		n.tab(
			{ id = "inverse_config" },
			n.rows(
				{ flex = 0 },
				render_main_title("Many-to-One: Inverse Side (One-to-Many) Configuration"),
				n.gap(1),
				select_one.render_component({
					label = "Collection Type",
					data = signal.collection_type_data,
					signal = signal,
					signal_key = "collection_type",
					autofocus = true,
					size = 3,
				}),
				select_many.render_component({
					title = "Inverse Side Cascade Types",
					data = signal.inverse_cascade_data,
					signal = signal,
					signal_key = "inverse_side_cascades",
					size = 5,
				}),
				select_many.render_component({
					title = "Inverse Side Options",
					data = signal.inverse_side_other_data,
					signal = signal,
					signal_key = "inverse_side_other",
					size = 1,
				}),
				n.gap(1),
				n.columns(
					{ flex = 0 },
					n.button({
						flex = 1,
						label = "<- Previous",
						align = "center",
						on_press = function()
							signal.active_tab = "basic_config"
							-- Reset confirm button state based on mapping type
							local function get_signal_value(value)
								if type(value) == "table" and value.get_value then
									return value:get_value()
								end
								return value
							end
							local mapping_type = get_signal_value(signal.mapping_type)
							if mapping_type == "unidirectional_join_column" then
								signal.confirm_btn_hidden = false
							else
								signal.confirm_btn_hidden = true
							end
						end,
					}),
					render_confirm_button()
				)
			)
		)
	)
end

function M.render(_previous_button_fn, _entity_files)
	reset_signal()
	process_entity_files(_entity_files)
	renderer:render(components(_previous_button_fn))
end

return M
