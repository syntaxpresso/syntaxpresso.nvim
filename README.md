```lua
return {
  "syntaxpresso/syntaxpresso.nvim",
  dir = <CUSTOM_PLUGIN_SRC_DIR>,
  config = function()
    require("syntaxpresso").setup({
      executable_path = "CUSTOM_BINARY_PATH"
    })
  end,
  dependencies = {
    'grapp-dev/nui-components.nvim',
    'MunifTanjim/nui.nvim',
  }
}
`` 
