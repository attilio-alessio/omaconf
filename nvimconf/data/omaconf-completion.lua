-- omaconf completion: keywords only, never buffer words.
-- blink.cmp ships buffer-word suggestions through the `buffer` source;
-- this spec removes it from the defaults and disables the provider so only
-- LSP keywords, paths and snippets complete.

return {
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      local default = opts.sources.default or { "lsp", "path", "snippets", "buffer" }
      opts.sources.default = vim.tbl_filter(function(s)
        return s ~= "buffer"
      end, default)
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.buffer = vim.tbl_extend(
        "force",
        opts.sources.providers.buffer or {},
        { enabled = false }
      )
    end,
  },
}
