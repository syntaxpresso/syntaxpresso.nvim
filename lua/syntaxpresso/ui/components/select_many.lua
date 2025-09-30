local n = require("nui-components")

-- @param t1 table: The table to be extended.
-- @param t2 table: The table whose elements are appended to t1.
-- @return table: The extended t1 table.
local function extend_array(t1, t2)
  for _, v in ipairs(t2) do
    table.insert(t1, v)
  end
  return t1
end
-- @param opts table: Configuration options for the select many component.
--   @field title string: The title for the tree border.
--   @field data table: A list of nodes for the tree, where each node is a table.
--   @field signal table: A table that stores selected node states.
--   @field signal_key string: The key in the `signal` table to store selected nodes.
--   @field signal_hidden_key string: The key in the signal table to store the hidden state of the tree component.
--   @field autofocus boolean|nil: Whether to autofocus the component (optional).
--   @field enable_all_option boolean: If true, enables an "All" option in the tree.
--   @field size number|nil: The size of the tree (optional).
--   @field on_select_callback function|nil: A callback function triggered on node selection (optional).
-- @return table: The rendered tree component.
local function render_component(opts)
  local to_add = {}
  return n.tree({
    border_label = opts.title,
    data = opts.data,
    size = opts.size or #opts.data,
    autofocus = opts.autofocus,
    on_select = function(selected_node, component)
      local tree = component:get_tree()
      local all_enable = opts.enable_all_option or false
      if all_enable and selected_node.text == "All" then
        local all_done = not selected_node.is_done
        for _, node in ipairs(opts.data) do
          node.is_done = all_done
        end
        opts.signal[opts.signal_key] = all_done and vim.tbl_map(function(node)
          return node.id
        end, opts.data) or {}
      else
        local done = not selected_node.is_done
        selected_node.is_done = done
        if done then
          table.insert(to_add, selected_node.id)
          opts.signal[opts.signal_key] = extend_array(to_add, opts.signal[opts.signal_key])
        else
          to_add = vim.tbl_filter(function(value)
            return value ~= selected_node.id
          end, to_add)
          opts.signal[opts.signal_key] = extend_array(to_add, opts.signal[opts.signal_key])
        end
        if all_enable then
          local all_checked = true
          for i = 2, #opts.data do
            if not opts.data[i].is_done then
              all_checked = false
              break
            end
          end
          opts.data[1].is_done = all_checked
        end
      end
      if opts.on_select_callback then
        opts.on_select_callback(opts.signal, selected_node, opts.data)
      end
      tree:render()
    end,
    prepare_node = function(node, line, _)
      if node.is_done then
        line:append("☑", "String")
      else
        line:append("◻", "Comment")
      end
      line:append(" ")
      line:append(node.text)
      return line
    end,
    hidden = opts.signal[opts.signal_hidden_key] or false
  })
end

return {
  render_component = render_component,
}
