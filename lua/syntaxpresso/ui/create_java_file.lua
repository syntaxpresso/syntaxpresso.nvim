local n = require("nui-components")
local text = require("syntaxpresso.ui.components.text")
local text_input = require("syntaxpresso.ui.components.text_input")
local command_runner = require("syntaxpresso.utils.command_runner")
local select_one = require("syntaxpresso.ui.components.select_one")

local M = {}

local renderer = n.create_renderer({
	height = 7,
	position = {
		row = "30%",
		col = "50%",
	},
})

local signal = n.create_signal({
	file_type = "class",
	file_name = "NewFile",
	package_name = "",
	package_list = {},
	file_type_list = {
		n.node({ id = "class", text = "Class", is_done = true }),
		n.node({ id = "interface", text = "Interface", is_done = false }),
		n.node({ id = "enum", text = "Enum", is_done = false }),
		n.node({ id = "record", text = "Record", is_done = false }),
		n.node({ id = "annotation", text = "Annotation", is_done = false }),
	},
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
				["file-type"] = signal.file_type:get_value(),
			}
			command_runner.execute("create-java-file", result, function(response, error)
				if error then
					vim.notify("Failed to create file: " .. error, vim.log.levels.ERROR)
				elseif response and response.succeed then
					vim.notify("Entity created successfully!", vim.log.levels.INFO)
					vim.schedule(function()
						vim.cmd("edit " .. response.data.filePath)
					end)
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
	if data.packages and data.packages.data then
		local root_package = data.packages.data.rootPackageName
		if data.packages.data.packages then
			for _, pkg in ipairs(data.packages.data.packages) do
				if pkg.packageName == root_package then
					table.insert(
						packages_list,
						n.node({ id = pkg.packageName, text = pkg.packageName, is_done = true })
					)
				else
					table.insert(
						packages_list,
						n.node({ id = pkg.packageName, text = pkg.packageName, is_done = false })
					)
				end
			end
		end
		signal.package_name = root_package
	end
	signal.package_list = packages_list
end

function M.render_create_java_file_ui(data)
	process_data(data)
	-- Create a table to hold the tree component reference
	local existing_packages_tree = {}
	local component = n.rows(
		{ flex = 0 },
		text.render_component({ text = "Create new Java file" }),
		select_one.render_component({
			label = "File type",
			data = signal.file_type_list,
			signal = signal,
			signal_key = "file_type",
			size = 5,
			autofocus = true,
		}),

		text_input.render_component({
			title = "File name",
			signal = signal,
			signal_key = "file_name",
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
