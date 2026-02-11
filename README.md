# QuickFail.nvim

## Setup

### lazy.nvim
```lua
return {
  {
    "imochoa/quickfail.nvim",
    cmd = { "QuickFailManual", "QuickFailSelect", "QuickFailReload", "QuickFailQuit" },
    opts = {},
    keys = {
      {
        "<leader>rs",
        function()
          require("quickfail").select()
        end,
        mode = { "n" },
        desc = "Quickfail Select",
      },
      {
        "<leader>rm",
        function()
          require("quickfail").manual()
        end,
        mode = { "n" },
        desc = "Quickfail Manual",
      },
      {
        "<leader>rq",
        function()
          require("quickfail").quit()
        end,
        mode = { "n" },
        desc = "Quickfail quit",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>r", group = "QuickFail", icon="󱐋" },
      },
    },
  },
}
```
