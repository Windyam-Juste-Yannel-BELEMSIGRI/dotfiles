-- ── Neovim 0.10 "glass // SOC" — config légère, sans gestionnaire de plugins
-- (aucun téléchargement : uniquement les fonctionnalités intégrées)
local o, g = vim.opt, vim.g
g.mapleader = " "
o.number = true; o.relativenumber = true; o.cursorline = true
o.termguicolors = true; o.signcolumn = "yes"; o.colorcolumn = "100"
o.expandtab = true; o.shiftwidth = 4; o.tabstop = 4; o.smartindent = true
o.ignorecase = true; o.smartcase = true; o.incsearch = true; o.inccommand = "split"
o.splitright = true; o.splitbelow = true; o.scrolloff = 6
o.undofile = true; o.swapfile = false; o.updatetime = 250
o.clipboard = "unnamedplus"          -- wl-clipboard
o.list = true; o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.mouse = "a"; o.laststatus = 3

-- Palette (miroir de foot) appliquée au thème intégré "habamax"
vim.cmd.colorscheme("habamax")
local p = { bg = "#1c1c1e", surface = "#2a2a2e", overlay = "#3a3a40", fg = "#e8e8ec",
            muted = "#a8a8ae", accent = "#7dd3c0", red = "#c07070", yellow = "#d8a657" }
local hl = function(n, v) vim.api.nvim_set_hl(0, n, v) end
hl("Normal", { fg = p.fg, bg = "NONE" })          -- transparence de foot conservée
hl("NormalFloat", { fg = p.fg, bg = p.surface })
hl("CursorLine", { bg = p.surface })
hl("CursorLineNr", { fg = p.accent, bold = true })
hl("LineNr", { fg = p.overlay })
hl("ColorColumn", { bg = p.surface })
hl("StatusLine", { fg = p.bg, bg = p.accent, bold = true })
hl("StatusLineNC", { fg = p.muted, bg = p.surface })
hl("Visual", { bg = "#2f4a45" })
hl("Search", { fg = p.bg, bg = p.yellow })
hl("WinSeparator", { fg = p.overlay })
hl("DiagnosticError", { fg = p.red })

-- Raccourcis
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<cr>", { desc = "enregistrer" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "quitter" })
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "explorateur netrw" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map("n", "<C-h>", "<C-w>h"); map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k"); map("n", "<C-l>", "<C-w>l")
map("v", "J", ":m '>+1<cr>gv=gv"); map("v", "K", ":m '<-2<cr>gv=gv")

-- Surbrillance brève du texte copié
vim.api.nvim_create_autocmd("TextYankPost", { callback = function() vim.highlight.on_yank({ timeout = 150 }) end })
-- Logs : coloration syslog pour *.log / auth.log
vim.filetype.add({ extension = { log = "messages" }, filename = { ["auth.log"] = "messages" } })
