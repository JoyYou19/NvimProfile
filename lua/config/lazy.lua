local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import any extras modules here
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.ui.mini-animate" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.clangd" },
    { import = "lazyvim.plugins.extras.lang.cmake" },
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        if type(opts.ensure_installed) == "table" then
          vim.list_extend(opts.ensure_installed, { "c", "cpp" })
        end
      end,
    },
    {
      "mfussenegger/nvim-dap",
      config = function() end,
      opts = function()
        local dap = require("dap")
        if not dap.adapters["codelldb"] then
          require("dap").adapters["codelldb"] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
              command = "codelldb",
              args = { "--port", "${port}" },
            },
          }
        end
        for _, lang in ipairs({ "c", "cpp" }) do
          dap.configurations[lang] = {
            {
              type = "codelldb",
              request = "launch",
              name = "Launch file",
              program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
              end,
              cwd = "${workspaceFolder}",
            },
            {
              type = "codelldb",
              request = "attach",
              name = "Attach to process",
              processId = require("dap.utils").pick_process,
              cwd = "${workspaceFolder}",
            },
          }
        end
      end,
    },

    {
      "sbdchd/neoformat",
      config = function()
        -- Enable autoformat
        vim.cmd("autocmd BufWritePre *.cpp Neoformat")

        -- Set clang-format as the default formatter for C++
        vim.g.neoformat_cpp_clangformat = {
          exe = "clang-format",
          args = { "--style=google" },
          stdin = true,
        }
        vim.g.neoformat_enabled_cpp = { "clangformat" }
      end,
    },
    {
      "mfussenegger/nvim-lint",
      event = {
        "BufReadPre",
        "BufNewFile",
      },
      config = function()
        local lint = require("lint")

        lint.linters_by_ft = {
          javascript = { "eslint_d" },
          typescript = { "eslint_d" },
          javascriptreact = { "eslint_d" },
          typescriptreact = { "eslint_d" },
          svelte = { "eslint_d" },
          kotlin = { "ktlint" },
          terraform = { "tflint" },
          ruby = { "standardrb" },
        }

        local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
          group = lint_augroup,
          callback = function()
            lint.try_lint()
          end,
        })

        vim.keymap.set("n", "<leader>ll", function()
          lint.try_lint()
        end, { desc = "Trigger linting for current file" })
      end,
    },
    {
      "neovim/nvim-lspconfig",
      opts = {
        servers = {
          -- Ensure mason installs the server
          clangd = {
            keys = {
              { "<leader>cR", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
            },
            root_dir = function(fname)
              return require("lspconfig.util").root_pattern(
                "Makefile",
                "configure.ac",
                "configure.in",
                "config.h.in",
                "meson.build",
                "meson_options.txt",
                "build.ninja"
              )(fname) or require("lspconfig.util").root_pattern(
                "compile_commands.json",
                "compile_flags.txt"
              )(fname) or require("lspconfig.util").find_git_ancestor(fname)
            end,
            capabilities = {
              offsetEncoding = { "utf-16" },
            },
            cmd = {
              "clangd",
              "--background-index",
              "--clang-tidy",
              "--header-insertion=iwyu",
              "--completion-style=detailed",
              "--function-arg-placeholders",
              "--fallback-style=llvm",
            },
            init_options = {
              usePlaceholders = true,
              completeUnimported = true,
              clangdFileStatus = true,
            },
          },
        },
        setup = {
          clangd = function(_, opts)
            local clangd_ext_opts = require("lazyvim.util").opts("clangd_extensions.nvim")
            require("clangd_extensions").setup(vim.tbl_deep_extend("force", clangd_ext_opts or {}, { server = opts }))
            return false
          end,
        },
      },
    },
    {
      "akinsho/flutter-tools.nvim",
      dependencies = { "nvim-lua/plenary.nvim", "stevearc/dressing.nvim" },
      config = function()
        require("flutter-tools").setup({
          debugger = {
            enabled = false,
            run_via_dap = false,
            register_configurations = function(_)
              require("dap").adapters.dart = {
                type = "executable",
                command = vim.fn.stdpath("data") .. "/mason/bin/dart-debug-adapter",
                args = { "flutter" },
              }

              require("dap").configurations.dart = {
                {
                  type = "dart",
                  request = "launch",
                  name = "Launch flutter",
                  dartSdkPath = "home/flutter/bin/cache/dart-sdk/",
                  flutterSdkPath = "home/flutter",
                  program = "${workspaceFolder}/lib/main.dart",
                  cwd = "${workspaceFolder}",
                },
              }
            end,
          },
          dev_log = {
            enabled = false,
            open_cmd = "tabedit",
          },
          lsp = {
            on_attach = function(client, bufnr) -- replace with your on_attach function
              -- your code here
            end,
            capabilities = vim.lsp.protocol.make_client_capabilities(), -- replace with your capabilities
          },
        })
      end,
    },
    {
      "dart-lang/dart-vim-plugin",
    },
    {
      "natebosch/vim-lsc",

      config = function()
        -- Apply the default configuration
        vim.g.lsc_auto_map = true
      end,
    },
    {
      "natebosch/vim-lsc-dart",
      config = function()
        -- Apply the default configuration
        vim.g.lsc_auto_map = true
      end,
    },

    -- import/override with your plugins
    --
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = true }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
