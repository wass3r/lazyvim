-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local opt = vim.opt

-- only use relativenumber in normal mode
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    opt.relativenumber = false
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    opt.relativenumber = true
  end,
})
-- end relativenumber only in normal mode
