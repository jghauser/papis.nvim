local MODREV, SPECREV = 'scm', '-1'
rockspec_format = '3.0'
package = 'papis.nvim'
version = MODREV .. SPECREV

description = {
  summary = 'Manage your bibliography from within your favourite editor',
  detailed = [[
  Papis.nvim is a neovim companion plugin for the bibliography manager papis.
  It's meant for all those who do academic and other writing in neovim and who
  want quick access to their bibliography from within the comfort of their editor.
  ]],
  labels = { 'neovim', 'plugin', },
  homepage = 'https://github.com/jghauser/papis.nvim',
  license = 'GPL3',
}

dependencies = {
  "lua >= 5.1, < 5.4",
  "nui.nvim",
  "sqlite",
  "pathlib.nvim",
}

source = {
  url = 'git://github.com/jghauser/papis.nvim',
}

build = {
  type = 'builtin',
  copy_directories = {
    "doc",
  }
}
