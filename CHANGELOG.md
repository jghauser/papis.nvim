# Changelog

## [0.3.3](https://github.com/jghauser/papis.nvim/compare/v0.3.2...v0.3.3) (2024-06-06)


### Bug Fixes

* **colors:** change hl group for normal text ([b3c8456](https://github.com/jghauser/papis.nvim/commit/b3c8456f796b1042f980d0a25f8a67978f908312))

## [0.3.2](https://github.com/jghauser/papis.nvim/compare/v0.3.1...v0.3.2) (2024-06-05)


### Bug Fixes

* add pathlib to luarocks dependencies ([4e8b1df](https://github.com/jghauser/papis.nvim/commit/4e8b1dfd3ad803257634f6a54062b4cb82d6963c))

## [0.3.1](https://github.com/jghauser/papis.nvim/compare/v0.3.0...v0.3.1) (2024-06-05)


### Features

* **config:** add info msg when Papis config import without changes ([0001954](https://github.com/jghauser/papis.nvim/commit/00019541930c2fa376daa8f11674fd29646b2b3b))
* default format_function_fn for markdown, not norg ([542eff0](https://github.com/jghauser/papis.nvim/commit/542eff04e021f400157422738138276f739e131e))
* use short titles when formatting notes ([6234a84](https://github.com/jghauser/papis.nvim/commit/6234a8489788d7f9a295c768e677a096380a15cb))


### Bug Fixes

* **config:** use correct config file if testing is enabled ([99aae36](https://github.com/jghauser/papis.nvim/commit/99aae368f277a57aa6a6b9ba28b29b3c0d18f0e6))
* **log:** add missing module ([a1aff00](https://github.com/jghauser/papis.nvim/commit/a1aff006e21fbd02b2e7e139354310383fdf5cd9))
* remove remaining plenary.path function calls ([2e8b846](https://github.com/jghauser/papis.nvim/commit/2e8b846e4ba180d1bc1c9893f931393c8f0ada32))


### Miscellaneous Chores

* release 0.3.1 ([68f8e79](https://github.com/jghauser/papis.nvim/commit/68f8e79c5b3fb3a294570e5e0c1c5f1ff1e18ee9))

## [0.3.0](https://github.com/jghauser/papis.nvim/compare/v0.2.0...v0.3.0) (2024-06-04)


### ⚠ BREAKING CHANGES

* replace plenary.path with pathlib

### Bug Fixes

* **colors:** use a default hl without bg ([e3f0ec3](https://github.com/jghauser/papis.nvim/commit/e3f0ec344b46760fac4e3a3d6e3141106749f76b))
* remove nvim-treesitter dependency ([cbed835](https://github.com/jghauser/papis.nvim/commit/cbed835b771d71a7b70383f3f17515cc8b3a82d1))


### Miscellaneous Chores

* release 0.3.0 ([917e9ae](https://github.com/jghauser/papis.nvim/commit/917e9aee8dd5d990020501ef41caacbaa186d0b8))


### Code Refactoring

* replace plenary.path with pathlib ([50c7057](https://github.com/jghauser/papis.nvim/commit/50c7057ad6365342621ef77cedfbd2135f173896))

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
