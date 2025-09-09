# Changelog

## [0.9.0](https://github.com/jghauser/papis.nvim/compare/v0.8.0...v0.9.0) (2025-09-08)


### Features

* **add:** add new module ([8d71411](https://github.com/jghauser/papis.nvim/commit/8d71411eae426a696e15ccc741be0b6887925bac))
* **ask:** Make picker descs consistent ([d18b18e](https://github.com/jghauser/papis.nvim/commit/d18b18ebc299a39df2ce7e6d8ee2a3022c399270))
* **init:** depracation warning about enable_modules option ([4a38a77](https://github.com/jghauser/papis.nvim/commit/4a38a77843b55b317158b7481ca7dc0a5bcbb919))
* make picker names consistent ([ecefc0f](https://github.com/jghauser/papis.nvim/commit/ecefc0f264898f148edfd14f309a2c0087d9b72b))
* more descriptive command descs ([f23f5af](https://github.com/jghauser/papis.nvim/commit/f23f5af2701e5d16902f366ccbb0ebe7203d372d))
* move enable_modules option to individual modules ([1f050a9](https://github.com/jghauser/papis.nvim/commit/1f050a98a74ba498d77fb4c0fcf4c311d7146b0e))
* move files into `papis` subdirs ([fb73312](https://github.com/jghauser/papis.nvim/commit/fb73312516a5c407fb334161687cda0608df830c))
* prepare 0.9.0 ([41c2ade](https://github.com/jghauser/papis.nvim/commit/41c2adedf2dc222a7123b8288170060aab92e69d))
* remove create_new_note_fn option ([8e7a715](https://github.com/jghauser/papis.nvim/commit/8e7a7152412359f2b018936282127e8fdd93f86e))
* support related_to keys ([b8644a2](https://github.com/jghauser/papis.nvim/commit/b8644a2c469c6a9023645930c9bf81ea416de12d))
* **utils:** mention ref when creating new notes ([58013eb](https://github.com/jghauser/papis.nvim/commit/58013eb97892b6931eb200e2eed81522937cedb7))


### Bug Fixes

* add sorter for telescope ([5a65559](https://github.com/jghauser/papis.nvim/commit/5a6555982a0bce8f2e0fd53ca0c899800f020efe)), closes [#135](https://github.com/jghauser/papis.nvim/issues/135)
* **at-cursor:** fix bug stemming from lua 1-indexing ([e21531d](https://github.com/jghauser/papis.nvim/commit/e21531da31a5a06111164c2f32e888d39041180f))
* **colors:** add missing and fix existing hl groups ([8f5a7bc](https://github.com/jghauser/papis.nvim/commit/8f5a7bccf8c9440e3384e6026b67ed5b9bdc4182))
* **completion.blink:** only start completion after first `-` ([4ef8531](https://github.com/jghauser/papis.nvim/commit/4ef8531dbc27152c1159990203439b1c3b04ed89))
* **config:** add forgotten enable option ([ad7babf](https://github.com/jghauser/papis.nvim/commit/ad7babfcbd2d000c4913cb6f0fc4442cccb0fe99))
* **config:** correctly check whether debug module is enabled ([aeb5b86](https://github.com/jghauser/papis.nvim/commit/aeb5b8689193b41b321591ab9af87eb346f4d613))
* disable `spell` for picker previewers ([4bd8928](https://github.com/jghauser/papis.nvim/commit/4bd8928973bf2523a1a9aecd84cb825ea924561f))
* fix problem from transition to new module enabling ([474e454](https://github.com/jghauser/papis.nvim/commit/474e454c129e98f3f773428e6d319c7f55932911))
* **log:** create parent directories for log file ([8fc0c9a](https://github.com/jghauser/papis.nvim/commit/8fc0c9a1f4c5d9ac17f1e5b87b15be3c95cfe22f))
* **search:** clear preview buffer ([e7ff4ae](https://github.com/jghauser/papis.nvim/commit/e7ff4ae7402254c9910b68dd7b61660baed9ae15))
* **utils:** handle empty lists when formatting strings ([9de4579](https://github.com/jghauser/papis.nvim/commit/9de45795d562ae6879d66946fd75b5dc8acbd4cb))
* **utils:** it's shorttitle, not shortitle ([1b8ed50](https://github.com/jghauser/papis.nvim/commit/1b8ed504f7ba99481cec0fc5b9cc28ea75fdfd07))
* **utils:** more robust pid check (fixes [#123](https://github.com/jghauser/papis.nvim/issues/123)) ([6cd7497](https://github.com/jghauser/papis.nvim/commit/6cd749730714abb1c749a4015743967e2605ebb7))


### Documentation

* **readme:** remove planned features section ([12c9698](https://github.com/jghauser/papis.nvim/commit/12c9698f475b6709aef6d8745763120a42efa924))


### Miscellaneous Chores

* prepare 0.9.0 ([8e60cd4](https://github.com/jghauser/papis.nvim/commit/8e60cd460de1a8a04f5da31e07a061734b854f7b))
* release 0.8.0 ([62cc876](https://github.com/jghauser/papis.nvim/commit/62cc87673989c24c0cc3cc6bff0af2b0ebcf9e88))
* release 0.9.0 ([409766f](https://github.com/jghauser/papis.nvim/commit/409766f891fa6a4cdbbad59db918347f732fc4da))
* release 0.9.0 ([d0de886](https://github.com/jghauser/papis.nvim/commit/d0de8864ea8de8bb23b1faef39db3256b0c7b6e2))

## [0.8.0](https://github.com/jghauser/papis.nvim/compare/v0.7.0...v0.8.0) (2025-07-27)


### ⚠ BREAKING CHANGES

* only handle tags as lists

### Features

* add snacks picker and move telescope codes to search ([355bd7c](https://github.com/jghauser/papis.nvim/commit/355bd7cfc7eb9b5add3db3b0dd665f28d74cbf8d))
* add snacks picker and move telescope codes to search ([783fe55](https://github.com/jghauser/papis.nvim/commit/783fe551c69007bd3111ed328d90c2a7cad1b1be))
* add typst support ([490bce4](https://github.com/jghauser/papis.nvim/commit/490bce48530b1379a4a11c10810ed0e36669040f))
* **completion:** add blink.cmp completion provider ([288f626](https://github.com/jghauser/papis.nvim/commit/288f626b50d537a0a4d1858bca9f6a4a5d5e757f))
* make keymaps less nested ([ab50f8c](https://github.com/jghauser/papis.nvim/commit/ab50f8c04ca4f383d342f773f0d51d8b95c60bf9))
* make keymaps less nested ([22a30d8](https://github.com/jghauser/papis.nvim/commit/22a30d8c494b9f9009c01fa80533dfd707099ba5))
* only handle tags as lists ([3990cef](https://github.com/jghauser/papis.nvim/commit/3990cefb47855029c3fcafc9e38b850b2dc427db))
* **papis-storage:** add error when tags key type isn't a list ([f7fe3b2](https://github.com/jghauser/papis.nvim/commit/f7fe3b2132dec216b44c8f59204421cfd56fe212))
* **papis-storage:** robust handling of library import errors ([11dff5a](https://github.com/jghauser/papis.nvim/commit/11dff5ac579616b8835f3d53fae8978bf4374617))
* **papis-storage:** robust handling of library import errors ([4b274a2](https://github.com/jghauser/papis.nvim/commit/4b274a2e315396202f6754cce5147e6e200a2c7c))
* **search:** pick provider automatically by default ([e90ac0f](https://github.com/jghauser/papis.nvim/commit/e90ac0f1900f8ac8d23b0db1d776679d0e700dc2))
* **search:** sort by time_added for snacks picker ([5c290f3](https://github.com/jghauser/papis.nvim/commit/5c290f307168ab63496f3cdaf865829c7ffcef4e))
* **search:** use keymaps from config for telescope and snacks ([c4566cb](https://github.com/jghauser/papis.nvim/commit/c4566cbfff7382ab5dd0c25a4dd43e49f10e6b02))


### Bug Fixes

* **at-cursor:** also strip white space at beginning and end of ref ([551920c](https://github.com/jghauser/papis.nvim/commit/551920cd8bcb5950d277a9627c6faf0cd6075977))
* **at-cursor:** also strip white space at beginning and end of ref ([788bbab](https://github.com/jghauser/papis.nvim/commit/788bbabd60fbbea184555fe3dd550fd30ded8953))
* **at-cursor:** correctly handle citet/citep in tex ([f8c0ec7](https://github.com/jghauser/papis.nvim/commit/f8c0ec7480d86f9105633557651e860f83a8c8ed))
* **at-cursor:** correctly handle citet/citep in tex ([e6bea82](https://github.com/jghauser/papis.nvim/commit/e6bea82de8ad781e54727fd42939501fcf3f17e8))
* **at-cursor:** get latex cite formats to work (v2) ([68457df](https://github.com/jghauser/papis.nvim/commit/68457df80b1330be656984e81d21755cfbd6952b))
* **at-cursor:** get latex cite formats to work (v2) ([73accac](https://github.com/jghauser/papis.nvim/commit/73accac713caf7e2fac68670a145e53f38ed77b3))
* **at-cursor:** refs are also terminated by `]` ([bf1ee96](https://github.com/jghauser/papis.nvim/commit/bf1ee966268fd128a9133d7d3a887744f5a16c76))
* **completion:** make sure to clear preview buffer for snacks ([07ba445](https://github.com/jghauser/papis.nvim/commit/07ba4455d6e8cd1d5225000a39fb8ed597e21e68))
* **completion:** remove some unnecessary source opts ([cd4f26c](https://github.com/jghauser/papis.nvim/commit/cd4f26c18c3bf085ff8c23ddc66649428ba8c8b3))
* **data:** make reset_db more robust ([c7fd4e7](https://github.com/jghauser/papis.nvim/commit/c7fd4e7bdf01647a24d0ec60d4fa238fd142bb77))
* **health:** correct error message about wrong yq ([5adfba2](https://github.com/jghauser/papis.nvim/commit/5adfba24b622a63f5a65ea0e6e85e7ebd040b572))
* **health:** correct error message about wrong yq ([657089e](https://github.com/jghauser/papis.nvim/commit/657089e007f6c99dfcf61585b9c73b6367d31faa))
* Papis search command for snacks ([e3e664d](https://github.com/jghauser/papis.nvim/commit/e3e664d1ae9420764fa57ed29b7825fe4c0b1cde))
* proper error handling ([96a30da](https://github.com/jghauser/papis.nvim/commit/96a30daa1ef5575393ac1b257cc2d6e60facf9af))
* restore cmp functionality for triggering after space ([9395828](https://github.com/jghauser/papis.nvim/commit/9395828c0d4ba37b2d8b7b39369140853b01b2f8))
* **search:** better error messages ([4d4d6b2](https://github.com/jghauser/papis.nvim/commit/4d4d6b2a9bbc5ff20ad8f280cb5c1daa1d821d4b))
* **search:** make snacks use precalculated values ([d2042b2](https://github.com/jghauser/papis.nvim/commit/d2042b2dab604a6a82ce8ab90cf3490e1bbfdd33))
* **search:** snacks source name ([e873c78](https://github.com/jghauser/papis.nvim/commit/e873c78e1a2719ce978278d7263592de35c04883))
* **search:** wrap snacks preview window if configured ([8b02402](https://github.com/jghauser/papis.nvim/commit/8b024028bb73bd7128e77b62b2ac1792b9b7677d))
* use different trigger characters for blink and cmp ([bd2bb27](https://github.com/jghauser/papis.nvim/commit/bd2bb27be46b9d07683b797dc9a39e5bff8363fe))
* **utils:** don't insert empty lines in preview window etc ([bf86ab7](https://github.com/jghauser/papis.nvim/commit/bf86ab7d4eef65a63297fef733d9a13f447dd928))

## [0.7.0](https://github.com/jghauser/papis.nvim/compare/v0.6.1...v0.7.0) (2024-09-03)


### ⚠ BREAKING CHANGES

* don't use autocmd to format new notes
* enable inserting multiple refs at once

### Features

* enable acting on multiple selections in telescope ([091e6df](https://github.com/jghauser/papis.nvim/commit/091e6df0ae29bf8749df0e004b93665f86a23311))
* enable inserting multiple refs at once ([16a0e56](https://github.com/jghauser/papis.nvim/commit/16a0e565c7a5d5515b794f1e9ef698e00a999a2d))
* **health:** add check for completion ([4492155](https://github.com/jghauser/papis.nvim/commit/44921556aaa5aa774342ce14713e83949c3b712f))
* **health:** add check for papis-storage ([82eef18](https://github.com/jghauser/papis.nvim/commit/82eef188f7babf4d64549b32d3ba93925e5c687f))
* **search:** only insert ref_prefix + ref if inserting into existing citation ([1c513b2](https://github.com/jghauser/papis.nvim/commit/1c513b2f3420e5fa46779bb83514a307a37edf3d))
* **utils:** handle opening multiple notes ([70dea91](https://github.com/jghauser/papis.nvim/commit/70dea91c3867069d0207d5d420bd42d9dddb7cc2))


### Bug Fixes

* **at-cursor:** bring file icon in line with search module ([71a32b1](https://github.com/jghauser/papis.nvim/commit/71a32b1aae54931781d7a5c7f981d30d8f34cda1))
* **health:** don't force start papis ([8c6d53b](https://github.com/jghauser/papis.nvim/commit/8c6d53ba2ddb64d200a1b382a13fbc29e68ce309))


### Code Refactoring

* don't use autocmd to format new notes ([3c5bb86](https://github.com/jghauser/papis.nvim/commit/3c5bb8621d666e0813f2900fb46cc85631b8713e))

## [0.6.1](https://github.com/jghauser/papis.nvim/compare/v0.6.0...v0.6.1) (2024-07-29)


### Features

* add logo ([a978704](https://github.com/jghauser/papis.nvim/commit/a978704abea8bb2aa8e272796f28f9e9a723ac9e))
* **fs-watcher:** add debounce and deferred handling ([2e2916f](https://github.com/jghauser/papis.nvim/commit/2e2916f066188391f03b5db4cf2e9aea882e9269))
* **init:** better logging ([c73f255](https://github.com/jghauser/papis.nvim/commit/c73f2559601d12f04d2421b610e7512b4ffadab7))
* **sqlite-wrapper:** make `has_schema_changed` more sophisticated ([ff8ae82](https://github.com/jghauser/papis.nvim/commit/ff8ae82c5a7a9a4b9200b59a91a7a2d952442490))


### Bug Fixes

* **fs-watcher:** correct typos ([1126504](https://github.com/jghauser/papis.nvim/commit/112650441a8a8caecea92c4278260957ebb999e3))
* **init:** fix db tbl empty check ([286b9d3](https://github.com/jghauser/papis.nvim/commit/286b9d35a94d469e5b04315cd2ed1a7f1fb56e92))
* **init:** load commands before modules ([6cacc32](https://github.com/jghauser/papis.nvim/commit/6cacc329aefec76cf7d42c6c1270df0770966ea8))
* make some `notify` into `log` ([6f1cf00](https://github.com/jghauser/papis.nvim/commit/6f1cf00385d9b6cb522238c6d16627694e2e9e4a))
* **search:** ensure metadata table always has entry row ([d7bcc4c](https://github.com/jghauser/papis.nvim/commit/d7bcc4cc3f729595f3e3778b2e7e42eca27c3b75))
* **search:** regenerate telescope precalc on demand ([f9d1e72](https://github.com/jghauser/papis.nvim/commit/f9d1e721355bdccd578bf09a7ddb16e5c2bb95f0))
* **sqlite-wrapper:** create tbl after dropping if schema change ([ae45382](https://github.com/jghauser/papis.nvim/commit/ae45382fafb6fad626dae153d9e0bcd6cbdf27ec))
* **sqlite-wrapper:** set required to `true` not string `"true"` ([d41100a](https://github.com/jghauser/papis.nvim/commit/d41100a1c3491ec0a396fa7c90d0649f3a7fde20))

## [0.6.0](https://github.com/jghauser/papis.nvim/compare/v0.5.1...v0.6.0) (2024-07-03)


### ⚠ BREAKING CHANGES

* **at-cursor:** add icon to at-cursor popup

### Features

* **at-cursor:** add icon to at-cursor popup ([4eeb7bc](https://github.com/jghauser/papis.nvim/commit/4eeb7bc4cbc603dd4cf6826297186fccbf763d37))
* check for schema changes on startup ([850988c](https://github.com/jghauser/papis.nvim/commit/850988cba3726147a27d2bc3820b6b0ddb1b9cce))


### Bug Fixes

* **health:** checkhealth should be normal startup condition ([684d6d2](https://github.com/jghauser/papis.nvim/commit/684d6d228bb5107ddb820070eef0f2c2296d9973))
* **health:** force start papis ([a2b3bf3](https://github.com/jghauser/papis.nvim/commit/a2b3bf32827da69a2932add285b174ee03822abf))
* **init:** only ever run loadPapis autocmd once ([4a09b98](https://github.com/jghauser/papis.nvim/commit/4a09b98bd705709917164cbcadada85f901b6768))
* **keymaps:** create buffer local keymaps for all matching buffers ([c30be92](https://github.com/jghauser/papis.nvim/commit/c30be924fb5a17188eec89d4f766349caf514495))
* make icon style more consistent ([745983b](https://github.com/jghauser/papis.nvim/commit/745983b8cd816f41f847a5bfaae826c3bff9af2c))
* only start papis.nvim once ([a5ffbd0](https://github.com/jghauser/papis.nvim/commit/a5ffbd0b9169bc597322fa55fc3b22bb74c73b7e))
* **search:** don't deepcopy, use metatable ([9322c41](https://github.com/jghauser/papis.nvim/commit/9322c41d1901fbd295bc0afa2588abee73b81528))
* **utils:** check if handle exists before closing ([db3632a](https://github.com/jghauser/papis.nvim/commit/db3632a038db9ad2ac4121c31f50d48a742b1dea))

## [0.5.1](https://github.com/jghauser/papis.nvim/compare/v0.5.0...v0.5.1) (2024-06-19)


### Bug Fixes

* **search:** copy entry_display from telescope before amending it ([c7b0f47](https://github.com/jghauser/papis.nvim/commit/c7b0f47445c86dbddfd8b81678be097bee99fbf1))

## [0.5.0](https://github.com/jghauser/papis.nvim/compare/v0.4.0...v0.5.0) (2024-06-18)


### ⚠ BREAKING CHANGES

* rework commands and keymaps
* add pretty icons

### Features

* add pretty icons ([f14ce7d](https://github.com/jghauser/papis.nvim/commit/f14ce7dcca7d05c25c837cb5d93a51bc6c1caacb))
* rework commands and keymaps ([93f56ca](https://github.com/jghauser/papis.nvim/commit/93f56caf854e093aac3d74eed4c51b88f75a432b))
* **search:** make telescope speedier ([c71dbe5](https://github.com/jghauser/papis.nvim/commit/c71dbe54e66595e9c88564ce709ab856ceba6cf6))
* use option from Papis to open external files ([4a0575f](https://github.com/jghauser/papis.nvim/commit/4a0575f3ea4697d4284839ec3a7682ad74164003))


### Bug Fixes

* add missing modules (oops) ([5e0c9c7](https://github.com/jghauser/papis.nvim/commit/5e0c9c7aec4f4f696661a715f898a46a0507a957))
* **data:** update precalc after updating db ([728e017](https://github.com/jghauser/papis.nvim/commit/728e0177759e4f21bdb782bc5342ff1d08d6ba62))
* **papis-storage:** remove all control chars from strings ([3cd93d0](https://github.com/jghauser/papis.nvim/commit/3cd93d02817bcc6b31c9c54d381cd55fe7cf5c74))
* **papis-storage:** remove newline/carrage return chars when importing ([31304b0](https://github.com/jghauser/papis.nvim/commit/31304b0e123cb059bfc803f5b3bc5b9f53142f8b))

## [0.4.0](https://github.com/jghauser/papis.nvim/compare/v0.3.3...v0.4.0) (2024-06-13)


### Features

* improve lazy-loading ([b685f69](https://github.com/jghauser/papis.nvim/commit/b685f696b25bd5c6d13a12d67f8a5ee53d9075e1))
* initially sort telescope entries by time-added ([eae91b8](https://github.com/jghauser/papis.nvim/commit/eae91b8864de336cc0bab044a227fcba6c12acf6))


### Miscellaneous Chores

* release 0.4.0 ([0fae1bf](https://github.com/jghauser/papis.nvim/commit/0fae1bf215193fb202eb3f107ed8aeef98033959))

## [0.3.3](https://github.com/jghauser/papis.nvim/compare/v0.3.2...v0.3.3) (2024-06-09)


### Bug Fixes

* **colors:** change hl group for normal text ([b3c8456](https://github.com/jghauser/papis.nvim/commit/b3c8456f796b1042f980d0a25f8a67978f908312))
* **config:** create logger early when no Papis config ([33d0dc2](https://github.com/jghauser/papis.nvim/commit/33d0dc21e713298cff88702414b29de335cdf253))
* **sqlite-wrapper:** create db folder recursively ([e5207e9](https://github.com/jghauser/papis.nvim/commit/e5207e9f17acf00b3582a603693b1b0218771d02)), closes [#67](https://github.com/jghauser/papis.nvim/issues/67)

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
