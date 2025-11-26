return {
  'neovim/nvim-lspconfig',
  dependencies = {
    {
      'mason-org/mason.nvim',
      opts = {
        ui = { border = 'rounded' },
      },
    },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'saghen/blink.cmp' },
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
        end

          --stylua: ignore start
          map('<leader>cn', vim.lsp.buf.rename, 'Rename variable')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code actions', { 'n', 'x' })
          -- map('<C-k>', function() vim.lsp.buf.signature_help({ border = 'rounded' }) end, 'Signature documentation')
          map('K', function() vim.lsp.buf.hover({ border = 'rounded' }) end, 'Hover documentation')
        --stylua: ignore end

        -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
        ---@param client vim.lsp.Client
        ---@param method vim.lsp.protocol.Method
        ---@param bufnr? integer some lsp support methods only in specific files
        ---@return boolean
        local function client_supports_method(client, method, bufnr)
          if vim.fn.has('nvim-0.11') == 1 then
            return client:supports_method(method, bufnr)
          else
            return client.supports_method(method, { bufnr = bufnr })
          end
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({ group = 'kickstart-lsp-highlight', buffer = event2.buf })
            end,
          })
        end

        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map('<leader>ch', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
          end, 'Toggle inlay hints')
        end
      end,
    })

    -- Diagnostic Config
    -- See :help vim.diagnostic.Opts
    vim.diagnostic.config({
      underline = true,
      virtual_text = false,
      severity_sort = true,
      float = {
        border = 'rounded',
        source = 'if_many',
      },
      signs = vim.g.have_nerd_font and {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
      } or {},
    })

    ---@class LspServersConfig
    local servers = {
      mason = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { disable = { 'missing-fields', 'missing-parameter' } },
              completion = { callSnippet = 'Replace' },
              hint = { enable = true },
            },
          },
        },

        harper_ls = {
          settings = {
            ['harper-ls'] = {
              userDictPath = vim.fn.stdpath('config') .. '/spell/en.utf-8.add',
              workspaceDictPath = vim.fn.getcwd() .. '/spell/en.utf-8.add',
              linters = {
                HowTo = false,
                ToDoHyphen = false,
                SentenceCapitalization = false,
                LongSentences = false,
              },
              markdown = {
                IgnoreLinkTitle = true,
              },
            },
          },
        },

        eslint = {
          settings = {
            workingDirectories = { mode = 'auto' },
          },
        },

        marksman = {
          on_attach = function(client)
            client.server_capabilities.completionProvider = nil
          end,
          handlers = {
            ['textDocument/publishDiagnostics'] = function(err, result, ctx, config)
              result.diagnostics = vim.tbl_filter(function(d)
                return not d.message:match('Ambiguous link')
                  and not d.message:match('Duplicate definition')
              end, result.diagnostics)
              vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
            end,
          },
        },
      },
      others = {
        -- zk = {},
      },
    }

    -- LSP servers (will be auto-enabled by mason-lspconfig)
    local lsp_servers = vim.tbl_keys(servers.mason or {})
    vim.list_extend(lsp_servers, {
      'eslint',
      'cssls',
      'html',
      'jsonls',
      'yamlls',
      'bashls',
      'emmet_language_server',
      'tailwindcss',
      'elixirls',
    })

    -- Formatters and linters (NOT LSP servers)
    local tools = {
      'stylua',
      'prettier',
      'prettierd',
      'markdownlint',
    }

    -- Install both servers and tools
    local ensure_installed = vim.list_extend(vim.deepcopy(lsp_servers), tools)

    require('mason-tool-installer').setup({
      ensure_installed = ensure_installed,
    })

    for server, config in pairs(vim.tbl_extend('keep', servers.mason, servers.others)) do
      if not vim.tbl_isempty(config) then
        vim.lsp.config(server, config)
      end
    end

    require('mason-lspconfig').setup({
      ensure_installed = {},
      automatic_enable = false,
    })

    -- Enable all LSP servers (both mason and others)
    local all_servers = vim.list_extend(vim.deepcopy(lsp_servers), vim.tbl_keys(servers.others))
    vim.lsp.enable(all_servers)
  end,
}
