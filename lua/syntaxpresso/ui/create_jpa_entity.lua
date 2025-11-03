local n = require("nui-components")
local text = require("syntaxpresso.ui.components.text")
local text_input = require("syntaxpresso.ui.components.text_input")
local command_runner = require("syntaxpresso.utils.command_runner")
local select_one = require("syntaxpresso.ui.components.select_one")

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
	local root_package = data.rootPackageName or ""
	if data.packages then
		for _, pkg in ipairs(data.packages) do
			table.insert(packages_list, n.node({ text = pkg.packageName, is_done = true, id = pkg.packageName }))
		end
	end
	signal.package_name = root_package
	signal.package_list = packages_list
end

function M.render_create_jpa_entity_ui(data)
	process_data(data.data)
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
		select_one.render_component({
			label = "Packages",
			data = signal.package_list,
			signal = signal,
			signal_key = "package_name",
			size = 5,
		}),
		text_input.render_component({
			title = "Package name",
			signal = signal,
			signal_key = "package_name",
			size = 1,
		}),
		n.columns({ flex = 0 }, render_confirm_button())
	)
	renderer:render(component)
end

return M
