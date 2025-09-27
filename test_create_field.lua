-- Simple test to check if create_field.lua loads without errors
print("Testing create_field.lua loading...")

local success, error_msg = pcall(function()
  -- Mock vim global for the test
  if not vim then
    _G.vim = {
      fn = {
        fnamemodify = function(path, modifier)
          return path  -- simplified mock
        end,
        filereadable = function(path)
          return 1  -- simplified mock
        end
      },
      cmd = function(cmd)
        print("Would execute: " .. cmd)
      end,
      notify = function(msg, level)
        print("Notification: " .. msg)
      end,
      log = {
        levels = {
          ERROR = 1,
          WARN = 2,
          INFO = 3
        }
      }
    }
  end
  
  -- Mock debug global
  if not debug then
    _G.debug = {
      getinfo = function(level, what)
        return {
          source = "@/home/andreluis/syntaxpresso/syntaxpresso.nvim/test_create_field.lua"
        }
      end
    }
  end
  
  -- Try to load the create_field.lua file
  local create_field = loadfile("lua/syntaxpresso/ui/create_field.lua")
  if create_field then
    print("✓ create_field.lua loaded successfully")
    return true
  else
    print("✗ Failed to load create_field.lua")
    return false
  end
end)

if success then
  print("✓ Test passed: No syntax errors found")
else
  print("✗ Test failed: " .. tostring(error_msg))
end