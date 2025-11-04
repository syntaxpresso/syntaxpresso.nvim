local n = require("nui-components")
local text = require("syntaxpresso.ui.components.text")
local text_input = require("syntaxpresso.ui.components.text_input")
local command_runner = require("syntaxpresso.utils.command_runner")

local M = {}

local renderer = n.create_renderer({ height = 7 })

local signal = n.create_signal({
	file_name = "NewEntity",
	package_name = "",
	package_list = {},
})

local function render_confirm_button()
	return n.button({
		flex = 1,
		label = "Confirm",
		align = "center",
		global_press_key = "<C-CR>",
		on_press = function()
			local result = {
				cwd = vim.fn.getcwd(),
				["package-name"] = signal.package_name:get_value(),
				["file-name"] = signal.file_name:get_value(),
			}
			command_runner.execute("create-jpa-entity", result, function(response, error)
				if error then
					vim.notify("Failed to create entity: " .. error, vim.log.levels.ERROR)
				elseif response and response.succeed then
					vim.notify("Entity created successfully!", vim.log.levels.INFO)
				else
					vim.notify("Entity creation completed", vim.log.levels.INFO)
				end
			end, nil)
			renderer:close()
		end,
	})
end

local function process_data(data)
	local packages_list = {}
	local root_package = data.rootPackageName
	if data.packages then
		for _, pkg in ipairs(data.packages) do
			if pkg.packageName == root_package then
				table.insert(packages_list, n.node({ text = pkg.packageName, is_done = true, id = pkg.packageName }))
			else
				table.insert(packages_list, n.node({ text = pkg.packageName, is_done = false, id = pkg.packageName }))
			end
		end
	end
	signal.package_name = root_package
	signal.package_list = packages_list
end

function M.render_create_jpa_entity_ui(data)
	process_data(data.data)
	-- Create a table to hold the tree component reference
	local existing_packages_tree = {}
	local component = n.rows(
		{ flex = 0 },
		text.render_component({ text = "Create new JPA Entity" }),
		text_input.render_component({
			title = "Entity name",
			signal = signal,
			signal_key = "file_name",
			autofocus = true,
			size = 1,
		}),
		n.select({
			border_label = "Existing packages",
			selected = signal.package_name,
			data = signal.package_list,
			multiselect = false,
			size = 5,
			on_select = function(selected, component)
				signal["package_name"] = selected.id
				existing_packages_tree = component:get_tree()
			end,
		}),
		text_input.render_component({
			title = "Package name",
			signal = signal,
			signal_key = "package_name",
			size = 1,
			on_change_callback = function(_)
				if existing_packages_tree then
					vim.schedule(function()
						if existing_packages_tree then
							local nodes = existing_packages_tree:get_nodes()
							for _, node in ipairs(nodes) do
								node.is_done = false
							end
							existing_packages_tree:render()
						end
					end)
				end
			end,
		}),
		n.columns({ flex = 0 }, render_confirm_button())
	)
	renderer:render(component)
end

return M
