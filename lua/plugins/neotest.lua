return {
  {
    "nvim-neotest/neotest",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
      { "nvim-neotest/neotest-go" },
    },
    keys = {
      {
        "<leader>cto",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "toggle summary",
      },
      {
        "<leader>ctw",
        function()
          require("neotest").output.open()
        end,
        desc = "toggle output window",
      },
      {
        "<leader>ctp",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "toggle output panel",
      },
      {
        "<leader>cta",
        function()
          require("neotest").run.run(vim.fn.getcwd())
        end,
        desc = "run all tests in current dir",
      },
      {
        "<leader>ctr",
        function()
          require("neotest").run.run()
        end,
        desc = "run nearest test",
      },
      {
        "<leader>ctd",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "debug nearest test",
      },
      {
        "<leader>cts",
        function()
          require("neotest").run.stop()
        end,
        desc = "stop nearest test",
      },
      {
        "<leader>ctc",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "run tests in current file",
      },
    },
    config = function()
      -- get neotest namespace (api call creates or returns namespace)
      local neotest_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
      }, neotest_ns)
      require("neotest").setup({
        -- your neotest config here
        adapters = {
          require("neotest-go"),
        },
        -- require("neotest-go")({
        --   experimental = {
        --     test_table = true,
        --   },
        --   args = { "-count=1", "-timeout=60s" }
        -- })
      })
      require("which-key").register({
        ["<leader>ct"] = { name = "+tests" },
      })
    end,
  },
}
