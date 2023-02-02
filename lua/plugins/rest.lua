return {
  {
    "NTBBloodbath/rest.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
    },
    ft = "http",
    keys = {
      { "<leader>rr", "<PLUG>RestNvim<CR>", desc = "run request under cursor" },
      { "<leader>rp", "<PLUG>RestNvimPreview<CR>", desc = "preview request as curl" },
      { "<leader>rl", "<PLUG>RestNvimLast<CR>", desc = "re-run last request" },
    },
    opts = {
      -- Open request results in a horizontal split
      result_split_horizontal = true,
      -- Keep the http file buffer above|left when split horizontal|vertical
      result_split_in_place = false,
      -- Skip SSL verification, useful for unknown certificates
      skip_ssl_verification = false,
      -- Highlight request on run
      highlight = {
        enabled = true,
        timeout = 150,
      },
      result = {
        -- toggle showing URL, HTTP info, headers at top the of result window
        show_url = true,
        show_http_info = true,
        show_headers = true,
        -- format response body
        formatters = {
          json = "jq",
          html = function(body)
            return vim.fn.system({ "tidy", "-i", "-q", "-" }, body)
          end,
        },
      },
      -- Jump to request line on run
      jump_to_request = false,
      env_file = ".env",
      custom_dynamic_variables = {},
      yank_dry_run = true,
    },
    config = function(_, opts)
      require("rest-nvim").setup(opts)
      require("which-key").register({
        ["<leader>r"] = { name = "+rest" },
      })
    end,
  },
}
