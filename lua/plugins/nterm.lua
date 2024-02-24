return {
  {
    "Olical/aniseed",
  },
  {
    "jlesquembre/nterm.nvim",
    config = function()
      require("nterm.main").init({
        maps = true, -- load default mappings
        shell = "bash",
        size = 20,
        direction = "horizontal", -- horizontal or vertical
        popup = 2000, -- Number of milliseconds to show the info about the command. 0 to disable
        popup_pos = "SE", --  one of "NE" "SE" "SW" "NW"
        autoclose = 2000, -- If command is successful, close the terminal after that number of milliseconds. 0 to disable
      })

      -- Optional, if you want to use the telescope extension
    end,
  },
  -- other plugins
}
