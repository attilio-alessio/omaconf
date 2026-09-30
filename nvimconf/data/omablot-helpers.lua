-- omablot helpers: purist Vim motions with memory-friendly helpers.
-- This file is owned by omablot (module 33-nvim.sh). Omarchy regenerates
-- lua/plugins/theme.lua on every `omarchy theme set`, but never touches
-- this file, so helpers survive theme switches untouched.
--
-- What you get:
--   * which-key groups with English labels: pause on <leader> and read
--   * <leader>h group ("helper"): searchable cheatsheet of every keymap,
--     plugin manager, LSP servers, diagnostics
--   * absolute line numbers only, fast which-key popup

-- 1. Absolute line numbers, always (never relative)
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.timeoutlen = 350

-- 2. Labeled which-key groups (English, glanceable)
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>h", group = "help", icon = "󰋖" },
    { "<leader>f", group = "find", icon = "" },
    { "<leader>g", group = "git", icon = "" },
    { "<leader>s", group = "search", icon = "" },
    { "<leader>x", group = "errors", icon = "󰷉" },
    { "<leader>c", group = "code", icon = "" },
    { "<leader>u", group = "ui", icon = "󰙵" },
    { "<leader>b", group = "buffer", icon = "󰓩" },
    { "<leader>t", group = "terminal/test", icon = "" },
    { "<leader>d", group = "debug", icon = "" },
  })
end

local map = vim.keymap.set

-- 3. The memory helpers: everything searchable, everything described
-- (Snacks picker is LazyVim's picker; Telescope is not installed)
map("n", "<leader>hh", "<cmd>lua Snacks.picker.keymaps()<cr>", { desc = "Cheatsheet: all keymaps" })
map("n", "<leader>hH", "<cmd>lua Snacks.picker.help()<cr>", { desc = "Vim help (manual)" })
map("n", "<leader>hl", "<cmd>Lazy<cr>", { desc = "Plugins: list and update" })
map("n", "<leader>hM", "<cmd>Mason<cr>", { desc = "LSP: installed servers" })
map("n", "<leader>hc", "<cmd>checkhealth<cr>", { desc = "nvim diagnostics" })
map("n", "<leader>hm", "<cmd>messages<cr>", { desc = "Recent messages" })
map("n", "<leader>hN", "<cmd>lua Snacks.picker.notifications()<cr>", { desc = "Recent notifications" })
map("n", "<leader>hn", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<leader>hr", "<cmd>lua Snacks.picker.registers()<cr>", { desc = "Registers: contents" })
map("n", "<leader>h:", "<cmd>lua Snacks.picker.command_history()<cr>", { desc = "Recent commands" })

-- Purists save with :w and quit with :q; LazyVim already maps <C-s> to
-- save and <leader>qq to quit all, so nothing is overridden here.

return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>h", group = "help", icon = "󰋖" },
      },
    },
  },
}
