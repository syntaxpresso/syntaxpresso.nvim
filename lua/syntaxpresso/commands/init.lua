local create_java_file = require("syntaxpresso.commands.create_java_file")
local create_jpa_repository = require("syntaxpresso.commands.create_jpa_repository")
local get_info = require("syntaxpresso.commands.get_info")
local get_main_class = require("syntaxpresso.commands.get_main_class")
local rename = require("syntaxpresso.commands.rename")

local M = {}

M.create_java_file = create_java_file
M.create_jpa_repository = create_jpa_repository
M.get_info = get_info
M.get_main_class = get_main_class
M.rename = rename

return M
