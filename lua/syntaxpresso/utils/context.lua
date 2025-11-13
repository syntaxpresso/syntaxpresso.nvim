local M = {}

---Get the current buffer context for Java operations
---@param bufnr number|nil Buffer number (default: current buffer)
---@return table context Contains cwd, entity_file_path, entity_file_b64_src, buffer_lines
function M.get_buffer_context(bufnr)
	bufnr = bufnr or 0
	local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local entity_file_path = vim.api.nvim_buf_get_name(bufnr)
	local entity_file_b64_src = vim.base64.encode(table.concat(buffer_lines, "\n"))
	local cwd = vim.fn.getcwd()

	return {
		cwd = cwd,
		entity_file_path = entity_file_path,
		entity_file_b64_src = entity_file_b64_src,
		buffer_lines = buffer_lines,
	}
end

---Get just the working directory
---@return string
function M.get_cwd()
	return vim.fn.getcwd()
end

---Get buffer content as base64
---@param bufnr number|nil Buffer number (default: current buffer)
---@return string
function M.get_buffer_b64(bufnr)
	bufnr = bufnr or 0
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	return vim.base64.encode(table.concat(lines, "\n"))
end

---Get the current buffer file path
---@param bufnr number|nil Buffer number (default: current buffer)
---@return string
function M.get_buffer_path(bufnr)
	bufnr = bufnr or 0
	return vim.api.nvim_buf_get_name(bufnr)
end

return M
