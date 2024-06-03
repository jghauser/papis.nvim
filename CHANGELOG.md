# Changelog

## [0.2.0](https://github.com/jghauser/papis.nvim/compare/v0.1.0...v0.2.0) (2024-06-03)


### ⚠ BREAKING CHANGES

* add better handling of Papis config
* **commands:** remove `PapisStart` command
* handle only autostart on filetypes, not filenames

### remove

* **commands:** remove `PapisStart` command ([9d37fd9](https://github.com/jghauser/papis.nvim/commit/9d37fd9001bd56012ee1b7f671b151db0208678f))
* handle only autostart on filetypes, not filenames ([2a0f826](https://github.com/jghauser/papis.nvim/commit/2a0f82658e1144f1025fca74e50e94266d93dd62))


### Features

* add better handling of Papis config ([029548e](https://github.com/jghauser/papis.nvim/commit/029548e3a90da2990aa4e7ab66b902e877795925))
* **commands:** make all commands buffer local ([20026a4](https://github.com/jghauser/papis.nvim/commit/20026a4278ad9f784e5b0754b1ecf6a732af09ee))
* **config:** add testing module ([077c46e](https://github.com/jghauser/papis.nvim/commit/077c46ea1c73c059c6de572f36007a4d1050cb98))
* **keymaps:** make all keymaps buffer local ([0b82cb5](https://github.com/jghauser/papis.nvim/commit/0b82cb57441bef6331b3f44a672864de71348151))


### Bug Fixes

* **colors:** this time really get the colors right ([1be3c9f](https://github.com/jghauser/papis.nvim/commit/1be3c9fa2f9719caf448a59aac2cf7784568057e))
* **config:** drop config before re-importing ([3814a6d](https://github.com/jghauser/papis.nvim/commit/3814a6dbd3cc1d8b08e8248a90c5eb94d2b2eda3))
* **config:** fix running without testing module ([76bdb14](https://github.com/jghauser/papis.nvim/commit/76bdb14212c3b3b20b034b4775fe777569493ad5))
* **config:** handle when papis options are rm'd from papis.nvim ([bf34de4](https://github.com/jghauser/papis.nvim/commit/bf34de442495554efa573166c7f6686b3bf30c1e))
* **health:** replace deprecated functions ([b24bfc2](https://github.com/jghauser/papis.nvim/commit/b24bfc242e538f9f16b02a5f5e004d33d5326f18))
* **highlights:** fit with neovim default theme ([280a994](https://github.com/jghauser/papis.nvim/commit/280a9944960a4dc2ad1818c46822bcd0d03c852c))
* **telescope:** remove vim.print ([a562767](https://github.com/jghauser/papis.nvim/commit/a5627672bc981a99633cf6c3989538f7793e2842))


### Miscellaneous Chores

* release 0.2.0 ([22944f8](https://github.com/jghauser/papis.nvim/commit/22944f8713db2e99071b1c209fdabc6077b19a0d))
