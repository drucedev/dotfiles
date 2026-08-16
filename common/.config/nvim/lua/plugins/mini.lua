return {
  {
    "nvim-mini/mini.files",
    opts = {
      mappings = {
        go_in = "<CR>",
        go_in_plus = "L",
        go_out = "_",
        go_out_plus = "H",
      },
    },
    keys = {
      {
        "-",
        function()
          require("mini.files").open()
        end,
        desc = "Toggle mini file explorer",
      },
    },
  },
}
