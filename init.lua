local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
                "git",
                "clone",
                "--filter=blob:none",
                "https://github.com/folke/lazy.nvim.git",
                "--branch=stable", -- latest stable release
                lazypath,
        })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
        'mfussenegger/nvim-dap',
        'rcarriga/nvim-dap-ui',
        'mxsdev/nvim-dap-vscode-js',
        'nvim-treesitter/nvim-treesitter-context',
        'prettier/vim-prettier',
        'neovim/nvim-lspconfig',    -- Collection of configurations for built-in LSP client
        'hrsh7th/nvim-cmp',         -- Autocompletion plugin
        'hrsh7th/cmp-nvim-lsp',     -- LSP source for nvim-cmp
        'saadparwaiz1/cmp_luasnip', -- Snippets source for nvim-cmp
        {
                "L3MON4D3/LuaSnip",
                dependencies = { "rafamadriz/friendly-snippets" },
        },                                 -- Snippets plugin
        'nvim-treesitter/nvim-treesitter', -- Highlight, edit, and navigate code
        'wiliamks/nice-reference.nvim',
        'kylechui/nvim-surround',
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
        'tjdevries/express_line.nvim',
        'lewis6991/gitsigns.nvim',
        {
                "folke/tokyonight.nvim",
                lazy = false,
                priority = 1000,
                opts = {},
        },
        { 'akinsho/bufferline.nvim', requires = 'nvim-tree/nvim-web-devicons' },
        "mickael-menu/zk-nvim",
        "ggandor/leap.nvim",
        "ggandor/leap-ast.nvim",
        'numToStr/Comment.nvim',
        "ellisonleao/gruvbox.nvim",
})


local options = { noremap = true }
vim.wo.relativenumber = true
vim.wo.number = true
vim.opt.clipboard = "unnamedplus"
vim.opt.spelloptions = "camel"
vim.opt.spelllang = 'en_us'
vim.opt.spell = true
vim.opt.errorformat =
"%f:%l:%c - error%m" -- packages/legacy-web/src/workflows/containers/WorkflowLaunchContainer.tsx:52:33 - error
vim.opt.shell = "/bin/zsh"
vim.opt.makeprg =
'cd /usr/local/repos/ironclad/harbor && yarn type-check-all --parallel=8 --output-style=static \\| gsed \'s/\x1b\\[[0-9;]*[mGKHF]//g\''
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.foldmethod = "indent"
vim.opt.foldenable = false
vim.opt.foldlevel = 99
vim.opt.cursorline = true
vim.opt.smartindent = true
vim.o.background = "dark"
vim.keymap.set("i", "jj", "<Esc>", options)
vim.keymap.set('n', 'F', ":PrettierAsync<CR>", options)
vim.g.mapleader = ';'
vim.g.maplocalleader = ';'
-- Add additional capabilities supported by nvim-cmp
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local lspconfig = require('lspconfig')

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp
local servers = { 'dafny', 'lua_ls', 'yamlls', 'tsserver', 'gleam' }
for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup {
                -- on_attach = my_custom_on_attach,
                capabilities = capabilities,
        }
end

-- luasnip setup
local luasnip = require 'luasnip'
require("luasnip.loaders.from_vscode").lazy_load()

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
        snippet = {
                expand = function(args)
                        luasnip.lsp_expand(args.body)
                end,
        },
        mapping = cmp.mapping.preset.insert({
                ['<C-u>'] = cmp.mapping.scroll_docs(-4), -- Up
                ['<C-d>'] = cmp.mapping.scroll_docs(4),  -- Down
                -- C-b (back) C-f (forward) for snippet placeholder navigation.
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<CR>'] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                },
                ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                                cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                                luasnip.expand_or_jump()
                        else
                                fallback()
                        end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                                cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                                luasnip.jump(-1)
                        else
                                fallback()
                        end
                end, { 'i', 's' }),
        }),
        sources = {
                { name = 'nvim_lsp' },
                { name = 'luasnip' },
        },
}
-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
                vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = buffer,
                        callback = function()
                                vim.lsp.buf.format { async = false }
                        end
                })
                -- Enable completion triggered by <c-x><c-o>
                vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

                -- Buffer local mappings.
                -- See `:help vim.lsp.*` for documentation on any of the below functions
                local opts = { buffer = ev.buf }
                vim.keymap.set('n', 'gd', vim.lsp.buf.declaration, opts)
                vim.keymap.set('n', '<F24>', function()
                        require('telescope.builtin').lsp_references()
                end, { noremap = true, silent = true })
                vim.keymap.set('n', '<F12>', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
                vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
                vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
                vim.keymap.set('n', '<space>wl', function()
                        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, opts)
                vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
                vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
                vim.keymap.set('n', '<space>f', function()
                        vim.lsp.buf.format { async = true }
                end, opts)
        end,
})
vim.cmd [[colorscheme tokyonight-storm]]
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.git_status, {})
vim.keymap.set('n', '<leader>ft', builtin.lsp_document_symbols, {})
vim.keymap.set('n', '<leader>fq', builtin.quickfix, {})
vim.keymap.set('n', '<leader>fs', builtin.current_buffer_fuzzy_find, {})
vim.keymap.set('n', '<leader>fr', builtin.registers, {})
vim.keymap.set('n', '<leader>fu', builtin.resume, {})

require('el').setup {
        -- An example generator can be seen in `Setup`.
        -- A default one is supplied if you do not want to customize it.
}
require('gitsigns').setup {
        on_attach = function(bufnr)
                local gs = package.loaded.gitsigns

                local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map('n', ']c', function()
                        if vim.wo.diff then return ']c' end
                        vim.schedule(function() gs.next_hunk() end)
                        return '<Ignore>'
                end, { expr = true })

                map('n', '[c', function()
                        if vim.wo.diff then return '[c' end
                        vim.schedule(function() gs.prev_hunk() end)
                        return '<Ignore>'
                end, { expr = true })

                -- Actions
                map('n', '<leader>hs', gs.stage_hunk)
                map('n', '<leader>hr', gs.reset_hunk)
                map('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end)
                map('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end)
                map('n', '<leader>hS', gs.stage_buffer)
                map('n', '<leader>hu', gs.undo_stage_hunk)
                map('n', '<leader>hR', gs.reset_buffer)
                map('n', '<leader>hp', gs.preview_hunk)
                map('n', '<leader>hb', function() gs.blame_line { full = true } end)
                map('n', '<leader>tb', gs.toggle_current_line_blame)
                map('n', '<leader>hd', gs.diffthis)
                map('n', '<leader>hD', function() gs.diffthis('~') end)
                map('n', '<leader>td', gs.toggle_deleted)

                -- Text object
                map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end
}
require('nvim-treesitter.configs').setup {
        -- A list of parser names, or "all" (the five listed parsers should always be installed)
        ensure_installed = { "markdown", "gleam", "c", "lua", "vim", "vimdoc", "query", "yaml" },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
        auto_install = true,
        ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
        -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!
        indent = {
                enable = true,
        },
        highlight = {
                enable = true,

                -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
                -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
                -- the name of the parser)
                -- list of language that will be disabled
                -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files

                -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                -- Using this option may slow down your editor, and you may see some duplicate highlights.
                -- Instead of true it can also be a list of languages
                additional_vim_regex_highlighting = { "markdown" },
        },
}

local dap, dapui = require("dap"), require("dapui")
dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
end
vim.keymap.set('n', '<F5>', function()
        require('dap').continue()
end)
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
-- vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
-- vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)
vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
vim.keymap.set('n', '<Leader>lp',
        function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
vim.keymap.set({ 'n', 'v' }, '<Leader>dh', function()
        require('dap.ui.widgets').hover()
end)
vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function()
        require('dap.ui.widgets').preview()
end)
vim.keymap.set('n', '<Leader>df', function()
        local widgets = require('dap.ui.widgets')
        widgets.centered_float(widgets.frames)
end)
vim.keymap.set('n', '<Leader>ds', function()
        local widgets = require('dap.ui.widgets')
        widgets.centered_float(widgets.scopes)
end)
require("dap-vscode-js").setup({
        -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
        debugger_path = "/usr/local/repos/vscode-js-debug",                                          -- Path to vscode-js-debug installation.
        -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
        adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
        -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
        -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
        -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
})

require("dap").configurations["typescript"] = {
        {
                type = "pwa-node",
                request = "attach",
                name = "Attach Job Runner",
                sourceMaps = true,
                skipFiles = { '<node_internals>/**' },
                port = 9239,
                cwd = "/usr/local/repos/ironclad/harbor",
        },
        {
                type = "pwa-node",
                request = "attach",
                name = "Attach Web Server",
                sourceMaps = true,
                skipFiles = { '<node_internals>/**' },
                port = 9229,
                cwd = "/usr/local/repos/ironclad/harbor",
        }

}
vim.opt.termguicolors = true
require("bufferline").setup {}
require("zk").setup({
        picker = "telescope"
})
require('leap').add_default_mappings()
require('Comment').setup()
require("nvim-surround").setup({})
require("dapui").setup()
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>ss', function() require 'leap-ast'.leap() end, {})
