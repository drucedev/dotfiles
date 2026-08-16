-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- Keep the picker shortcuts from the previous configuration alongside LazyVim's defaults.

vim.keymap.set("n", "<leader>pf", LazyVim.pick("files"), { desc = "Find files" })
vim.keymap.set("n", "<leader>ps", LazyVim.pick("grep_word"), { desc = "Search current word" })
vim.keymap.set("n", "<leader>vh", function()
  Snacks.picker.help()
end, { desc = "Search help" })
vim.keymap.set("n", "<leader>pk", function()
  Snacks.picker.keymaps()
end, { desc = "Search keymaps" })
