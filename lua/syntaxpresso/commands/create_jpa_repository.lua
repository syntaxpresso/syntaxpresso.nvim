local M = {}

-- Decompile a class using JDTLS
local function get_jdtls_class_content(uri)
	local original_win = vim.api.nvim_get_current_win()
	require("jdtls").open_classfile(uri)
	local new_buf = vim.api.nvim_get_current_buf()
	local content = vim.api.nvim_buf_get_lines(new_buf, 0, -1, false)
	vim.cmd("bdelete! " .. new_buf)
	vim.api.nvim_set_current_win(original_win)
	return content
end

-- Get URI for a symbol using LSP workspace/symbol
local function get_symbol_uri(symbol_name, callback)
	vim.lsp.buf_request(0, "workspace/symbol", { query = symbol_name }, function(err, result)
		if err or not result or vim.tbl_isempty(result) then
			callback(nil, "No symbols found for: " .. symbol_name)
			return
		end
		local uri = result[1].location.uri
		callback(uri, nil)
	end)
end

-- Read file and encode to base64
local function read_and_encode_file(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return nil, "Could not open file: " .. file_path
	end
	local content = file:read("*all")
	file:close()
	return vim.base64.encode(content), nil
end

-- Execute the create-jpa-repository command
local function execute_command(executable, entity_path, entity_b64_src, superclass_b64_src)
	local cmd_parts = { executable, "create-jpa-repository" }
	table.insert(cmd_parts, "--cwd=" .. vim.fn.getcwd())
	table.insert(cmd_parts, "--entity-file-path=" .. entity_path)
	table.insert(cmd_parts, "--entity-file-b64-src=" .. entity_b64_src)

	if superclass_b64_src then
		table.insert(cmd_parts, "--b64-superclass-source=" .. superclass_b64_src)
	end

	local output = {}
	local exit_code = nil

	local job_id = vim.fn.jobstart(cmd_parts, {
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(output, line)
					end
				end
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 and data[1] ~= "" then
				vim.notify("Error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
			end
		end,
		on_exit = function(_, code)
			exit_code = code
		end,
	})

	-- Wait for job to complete
	vim.fn.jobwait({ job_id })

	if exit_code ~= 0 then
		return nil, "Command failed with exit code: " .. exit_code
	end

	if #output == 0 then
		return nil, "No output from command"
	end

	-- Parse JSON response
	local raw_output = table.concat(output, "")
	local ok, response = pcall(vim.json.decode, raw_output)

	if not ok then
		return nil, "Failed to parse JSON response: " .. tostring(response)
	end

	return response, nil
end

-- Suggest using TUI when manual input is needed
local function suggest_tui_for_manual_input(callback)
	vim.notify(
		"No ID field detected in entity or superclasses. Please use :SyntaxpressoCreateJpaRepositoryTui to manually specify the ID field type.",
		vim.log.levels.ERROR
	)
	callback(nil, "No ID field found. Use TUI for manual input.")
end

-- Recursive resolution with LSP decompilation
local function execute_with_resolution(executable, entity_path, superclass_b64_src, callback, depth)
	depth = depth or 0

	-- Prevent infinite recursion
	if depth > 10 then
		callback(nil, "Maximum recursion depth reached (10). Circular inheritance?")
		return
	end

	-- Read and encode entity file
	local entity_b64_src, err = read_and_encode_file(entity_path)
	if not entity_b64_src then
		callback(nil, err)
		return
	end

	-- Execute command
	local response, cmd_err = execute_command(executable, entity_path, entity_b64_src, superclass_b64_src)
	if not response then
		callback(nil, cmd_err)
		return
	end

	-- Check if command succeeded
	if not response.succeed then
		callback(nil, response.errorReason or "Unknown error")
		return
	end

	-- Check response data - handle vim.NIL (which appears as userdata)
	local data = response.data
	if not data or type(data) ~= "table" then
		callback(nil, "Invalid response data structure")
		return
	end

	local repository = data.repository
	local superclass_type = data.superclass_type

	-- Check if repository exists (not nil and not vim.NIL)
	local has_repository = repository ~= nil and type(repository) == "table"
	-- Check if superclass_type exists (not nil and not vim.NIL)
	local has_superclass = superclass_type ~= nil and type(superclass_type) == "string"

	if has_repository then
		-- Success! Repository created
		callback(data, nil)
	elseif has_superclass then
		-- Need to resolve superclass
		vim.notify("ID field not found. Resolving superclass: " .. superclass_type, vim.log.levels.INFO)

		-- Get symbol URI via LSP
		get_symbol_uri(superclass_type, function(uri, symbol_err)
			if symbol_err then
				-- LSP resolution failed - cannot continue
				vim.notify(
					"Could not resolve superclass via LSP: "
						.. symbol_err
						.. "\nPlease use :SyntaxpressoCreateJpaRepositoryTui to manually specify the ID field.",
					vim.log.levels.ERROR
				)
				callback(nil, "LSP resolution failed: " .. symbol_err)
				return
			end

			-- Decompile the class
			local ok, content = pcall(get_jdtls_class_content, uri)
			if not ok then
				vim.notify(
					"Failed to decompile superclass: "
						.. tostring(content)
						.. "\nPlease use :SyntaxpressoCreateJpaRepositoryTui to manually specify the ID field.",
					vim.log.levels.ERROR
				)
				callback(nil, "Failed to decompile superclass: " .. tostring(content))
				return
			end

			-- Encode superclass source
			local source_code = table.concat(content, "\n")
			local superclass_b64 = vim.base64.encode(source_code)

			-- Recurse with superclass source
			execute_with_resolution(executable, entity_path, superclass_b64, callback, depth + 1)
		end)
	else
		-- No repository and no superclass - cannot continue
		suggest_tui_for_manual_input(callback)
	end
end

-- Main entry point
function M.execute_create_jpa_repository(executable)
	local entity_path = vim.fn.expand("%:p")

	-- Validate current file is a Java file
	if not entity_path:match("%.java$") then
		vim.notify("Current file is not a Java file", vim.log.levels.ERROR)
		return
	end

	-- Check if executable exists
	if vim.fn.filereadable(executable) ~= 1 then
		vim.notify("Syntaxpresso executable not found: " .. executable, vim.log.levels.ERROR)
		return
	end

	-- Start resolution process
	execute_with_resolution(executable, entity_path, nil, function(data, err)
		if err then
			vim.notify("Failed to create JPA repository: " .. err, vim.log.levels.ERROR)
		elseif data and data.repository and data.repository ~= vim.NIL then
			-- Open the created repository file
			local repo_path = data.repository.filePath
			if repo_path and repo_path ~= vim.NIL then
				vim.cmd("edit " .. repo_path)
				vim.notify("JPA repository created successfully!", vim.log.levels.INFO)
			else
				vim.notify("Repository created but file path not found in response", vim.log.levels.WARN)
			end
		else
			vim.notify("Unexpected response from create-jpa-repository command", vim.log.levels.ERROR)
		end
	end)
end

return M
