-- holder for local funtions
local M = {}

-- helper that prompts for args to pass to debug session
function M.get_arguments()
  local co = coroutine.running()
  if co then
    return coroutine.create(function()
      local args = {}
      vim.ui.input({ prompt = "Args: " }, function(input)
        args = vim.split(input or "", " ", {})
      end)
      coroutine.resume(co, args)
    end)
  else
    local args = {}
    vim.ui.input({ prompt = "Args: " }, function(input)
      args = vim.split(input or "", " ", {})
    end)
    return args
  end
end

-- load .env for debugger
-- credit: https://github.com/ray-x/go.nvim/blob/master/lua/go/env.lua
function M.load_env()
  local env = M.envfile()
  if vim.fn.filereadable(env) == 0 then
    return false
  end

  -- parse lines from file
  local lines = {}
  for line in io.lines(env) do
    -- filter out lines starting with #
    if string.sub(line, 1, 1) ~= "#" then
      lines[#lines + 1] = line
    end
  end

  -- create envs from file
  local envs = {}
  for _, envline in ipairs(lines) do
    -- scan for env variables in file, for example ENV=production
    for k, v in string.gmatch(envline, "([%w_]+)=([%w%c%p%z]+)") do
      envs[k] = v
    end
  end

  return envs
end

-- check for env file
function M.envfile()
  local cwd = vim.lsp.buf.list_workspace_folders()[1] or vim.fn.getcwd()
  local env_file = cwd .. "/" .. ".env" -- we don't care about windows ("\")

  if vim.fn.filereadable(env_file) == 1 then
    return env_file
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    dependencies = {
      {
        "theHamsta/nvim-dap-virtual-text",
        config = true,
      },
      {
        "rcarriga/nvim-dap-ui",
        keys = {},
        opts = {
          expand_lines = true,
          icons = { expanded = "▾", collapsed = "▸", circular = "" },
          mappings = {
            expand = { "<CR>", "<2-LeftMouse>" },
            open = "o",
            remove = "d",
            edit = "e",
            repl = "r",
            toggle = "t",
          },
          layouts = {
            {
              elements = {
                { id = "scopes", size = 0.33 },
                { id = "breakpoints", size = 0.17 },
                { id = "stacks", size = 0.25 },
                { id = "watches", size = 0.25 },
              },
              size = 0.33,
              position = "right",
            },
            {
              elements = {
                { id = "repl", size = 0.45 },
                { id = "console", size = 0.55 },
              },
              size = 0.27,
              position = "bottom",
            },
          },
          floating = {
            max_height = 0.9,
            max_width = 0.5,
            border = "single",
            mappings = {
              close = { "q", "<Esc>" },
            },
          },
        },
        config = function(_, opts)
          require("dapui").setup(opts)
        end,
      },
      {
        "nvim-telescope/telescope-dap.nvim",
      },
    },
    config = function()
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "", texthl = "", linehl = "", numhl = "" })
      require("dap").defaults.fallback.terminal_win_cmd = "enew"
      -- go configuration
      require("dap").configurations.go = {
        {
          type = "go",
          name = "Debug",
          request = "launch",
          program = "${file}",
          env = M.load_env,
        },
        {
          type = "go",
          name = "Debug (Arguments)",
          request = "launch",
          program = "${file}",
          args = M.get_arguments,
          env = M.load_env,
        },
        {
          type = "go",
          name = "Debug Package",
          request = "launch",
          program = "${fileDirname}",
          env = M.load_env,
        },
        {
          type = "go",
          name = "Debug test (go.mod)",
          request = "launch",
          mode = "test",
          program = "./${relativeFileDirname}",
          env = M.load_env,
        },
        {
          type = "go",
          name = "Attach (Pick Process)",
          mode = "local",
          request = "attach",
          processId = require("dap.utils").pick_process,
          env = M.load_env,
        },
        {
          type = "go",
          name = "Attach (127.0.0.1:9080)",
          mode = "remote",
          request = "attach",
          port = "9080",
          env = M.load_env,
        },
      }
      require("dap").adapters.go = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/dlv",
          args = { "dap", "-l", "127.0.0.1:${port}" },
        },
      }
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "dap-repl",
        callback = function()
          require("dap.ext.autocompl").attach()
        end,
      })
      require("which-key").register({
        ["<leader>d"] = { name = "+debug" },
        ["<leader>db"] = { name = "+breakpoints" },
        ["<leader>ds"] = { name = "+steps" },
        ["<leader>dv"] = { name = "+views" },
      })
    end,
    keys = {
      {
        "<leader>dbc",
        '<CMD>lua require("dap").set_breakpoint(vim.ui.input("Breakpoint condition: "))<CR>',
        desc = "conditional breakpoint",
      },
      {
        "<leader>dbl",
        '<CMD>lua require("dap").set_breakpoint(nil, nil, vim.ui.input("Log point message: "))<CR>',
        desc = "logpoint",
      },
      { "<leader>dbr", '<CMD>lua require("dap.breakpoints").clear()<CR>', desc = "remove all" },
      { "<leader>dbs", "<CMD>Telescope dap list_breakpoints<CR>", desc = "show all" },
      { "<leader>dbt", '<CMD>lua require("dap").toggle_breakpoint()<CR>', desc = "toggle breakpoint" },
      { "<leader>dc", '<CMD>lua require("dap").continue()<CR>', desc = "continue" },
      {
        "<leader>de",
        '<CMD>lua require("dap.ui.widgets").hover(nil, { border = "none" })<CR>',
        desc = "expression",
        mode = { "n", "v" },
      },
      { "<leader>dp", '<CMD>lua require("dap").pause()<CR>', desc = "pause" },
      --{ "<leader>dr", "<CMD>Telescope dap configurations<CR>", desc = "run" },
      {
        "<leader>dr",
        function()
          require("dap").continue()
          require("dapui").toggle({})
        end,
        desc = "run",
      },
      { "<leader>dsb", '<CMD>lua require("dap").step_back()<CR>', desc = "step back" },
      { "<leader>dsc", '<CMD>lua require("dap").run_to_cursor()<CR>', desc = "step to cursor" },
      { "<leader>dsi", '<CMD>lua require("dap").step_into()<CR>', desc = "step into" },
      { "<leader>dso", '<CMD>lua require("dap").step_over()<CR>', desc = "step over" },
      { "<leader>dsx", '<CMD>lua require("dap").step_out()<CR>', desc = "step out" },
      {
        "<leader>dx",
        function()
          require("dap").clear_breakpoints()
          require("dapui").toggle({})
          require("dap").terminate()
        end,
        desc = "terminate",
      },
      {
        "<leader>dvf",
        '<CMD>lua require("dap.ui.widgets").centered_float(require("dap.ui.widgets").frames, { border = "none" })<CR>',
        desc = "show frames",
      },
      {
        "<leader>dvs",
        '<CMD>lua require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes, { border = "none" })<CR>',
        desc = "show scopes",
      },
      {
        "<leader>dvt",
        '<CMD>lua require("dap.ui.widgets").centered_float(require("dap.ui.widgets").threads, { border = "none" })<CR>',
        desc = "show threads",
      },
    },
  },
}
