# Changelog

## 1.0.0 (2024-06-01)


### ⚠ BREAKING CHANGES

* **keymaps:** avoid keybind clash with nvim defaults
* use `papis_id` rather than `ref` to identify entries ([#21](https://github.com/jghauser/papis.nvim/issues/21))
* **papis-storage:** Remove dependency on lyaml (fixes #20)

### Features

* add option to always insert plain reference ([#15](https://github.com/jghauser/papis.nvim/issues/15)) ([15e3d01](https://github.com/jghauser/papis.nvim/commit/15e3d0160f52d024eaf7afa09a58e3e3e4d305fc))
* **config:** add norg cite format ([841d927](https://github.com/jghauser/papis.nvim/commit/841d927f3b6912cb8b2fd4ae880a3c4922c47fb4))
* luarocks support ([63a5379](https://github.com/jghauser/papis.nvim/commit/63a537961572978a5fba88151b11a1cfa1b8494c))
* **papis-storage:** Remove dependency on lyaml (fixes [#20](https://github.com/jghauser/papis.nvim/issues/20)) ([f36395c](https://github.com/jghauser/papis.nvim/commit/f36395c38a57b47f8ea63ef0dbc25f496521a802))
* **search:** prettier previews ([465f9ae](https://github.com/jghauser/papis.nvim/commit/465f9aec30274cdd7324318903f2fed6347fd85a))
* use `papis_id` rather than `ref` to identify entries ([#21](https://github.com/jghauser/papis.nvim/issues/21)) ([d0b2586](https://github.com/jghauser/papis.nvim/commit/d0b25864c390ba989a41285d5aa918a92066fba6))


### Bug Fixes

* **colors:** fix wrong bg for telescope results hl ([a27d7c1](https://github.com/jghauser/papis.nvim/commit/a27d7c1cdecce0ff85486aa9db1fa2493ed66837))
* **completion:** del mistaken print() ([546f28b](https://github.com/jghauser/papis.nvim/commit/546f28b6a2dff8c2b73c9bb180c23088d55d65c9))
* **completion:** fix completion triggering ([a3ec828](https://github.com/jghauser/papis.nvim/commit/a3ec828880c204da3d411a59a8c905c342246cf1))
* **completion:** handle missing tag_delimiter (fixes [#16](https://github.com/jghauser/papis.nvim/issues/16)) ([0e8edb6](https://github.com/jghauser/papis.nvim/commit/0e8edb6b18daabb2ddb77222c1ee9bb4812ee7d4))
* **config:** cite_format lua pattern for org ([06681f2](https://github.com/jghauser/papis.nvim/commit/06681f2c9f074af4cfe6779be1b82c440563d0d3))
* **config:** correct hl group name ([48c80cb](https://github.com/jghauser/papis.nvim/commit/48c80cb4500ecfe40515cca3517fd98cedd2b675))
* **config:** find and insert cite_format org ([4776f46](https://github.com/jghauser/papis.nvim/commit/4776f464a1fab2fa7710079f15c92d13896d2ee4))
* **config:** fix metagen in norg notes ([c6ff308](https://github.com/jghauser/papis.nvim/commit/c6ff3087fbfba1fc595a7f6d3c4f6707cee31979))
* **config:** remove some invalid filetypes ([c2bbd38](https://github.com/jghauser/papis.nvim/commit/c2bbd383a2f51825b9561053887f6c5edb49555f))
* **config:** revert change ([30e18b2](https://github.com/jghauser/papis.nvim/commit/30e18b2227cab5ea9625b0fdfc507479cdf95ced))
* **cursor:** better recognise `ref`s under cursor ([8baef8a](https://github.com/jghauser/papis.nvim/commit/8baef8a6d5da3a333e92ee6b560bb800023c2c1b))
* **cursor:** make commands work ([a9d5103](https://github.com/jghauser/papis.nvim/commit/a9d5103531e2ba96e2ca78e5144203ae880dc2fa))
* **cursor:** remove trailing '.:' in refs ([4bec772](https://github.com/jghauser/papis.nvim/commit/4bec77263ce4f53d145d4e28f3845127dfe5dfbb))
* ensure disabled modules are not used ([d10df5d](https://github.com/jghauser/papis.nvim/commit/d10df5d563309c7607bbc81af2738b9add851b48))
* Expand library directory specified by user ([#14](https://github.com/jghauser/papis.nvim/issues/14)) ([3af8560](https://github.com/jghauser/papis.nvim/commit/3af8560b37b99c4ad18317072981955e2f46ef12))
* **fs-watcher:** avoid erroneous msgs when adding files ([2de583a](https://github.com/jghauser/papis.nvim/commit/2de583a4520a40550860193b95308ea8e022b6e4))
* **fs-watcher:** this time for real avoid erroneous msgs ([0e487d1](https://github.com/jghauser/papis.nvim/commit/0e487d18690cd46ddc0ccfdfdfd3677b69e06128))
* handle malformatted yaml files (closes [#13](https://github.com/jghauser/papis.nvim/issues/13)) ([45d2d9c](https://github.com/jghauser/papis.nvim/commit/45d2d9c2ad50724a4bb936b78415c32153483a92))
* have both insert and find cite format ([03d1bf0](https://github.com/jghauser/papis.nvim/commit/03d1bf0ee22c1dff2e69ce7617152dfb1a10fc95))
* **health:** remove depracated require('health') ([52c9f9a](https://github.com/jghauser/papis.nvim/commit/52c9f9ac37d508deb2a4803ce2eb84f406cfd464))
* **keymaps:** avoid keybind clash with nvim defaults ([9aad147](https://github.com/jghauser/papis.nvim/commit/9aad14705da86b395413949a55487395d01ba566))
* **keymaps:** get rid of last c-p command ([68d2248](https://github.com/jghauser/papis.nvim/commit/68d2248e711a02b5195e0bc2ed8c220a61e7bd34))
* **keymaps:** make keymaps work when papis first loads ([9c49a02](https://github.com/jghauser/papis.nvim/commit/9c49a021e9719ded1023f62aed80dd5092c167ea))
* **keymaps:** only set keymaps for relevant buffers ([a47354f](https://github.com/jghauser/papis.nvim/commit/a47354ff68434381003db996016a26efe2ec6356))
* **keymaps:** only start papis search when pumvisible false ([d1381cb](https://github.com/jghauser/papis.nvim/commit/d1381cb37422f2752a4881bd2cc3dde462db1d77))
* make modules local variables ([dc88bbb](https://github.com/jghauser/papis.nvim/commit/dc88bbbb969855ff94e9116286c38d8cc4441c11))
* **papis-storage:** handle null values in yaml files ([bbeda0b](https://github.com/jghauser/papis.nvim/commit/bbeda0b79bf4efcea574408d58f98928bbcfcbd7))
* **search:** add descs to telescope commands ([2575569](https://github.com/jghauser/papis.nvim/commit/257556983f34e99f984618687ebf9332ecd5c107))
* solve issues with lazy-loading ([8233261](https://github.com/jghauser/papis.nvim/commit/82332619367aaac50412721117481374c7b852d1))
* **sqlite-wrapper:** make module local ([0c68bf4](https://github.com/jghauser/papis.nvim/commit/0c68bf441e4a995acbce2a444f021514eda56ae2))
* **sqlite:** avoid database locked errors ([55b145c](https://github.com/jghauser/papis.nvim/commit/55b145c27fd7abdba4bcb4d639db8082f819c55f))
* **tele:** get ref insert to paste after cursor ([5be46c4](https://github.com/jghauser/papis.nvim/commit/5be46c4c5559477fbe51a382473373861e077bac))
* **utils:** correctly handle opening nonexistent attachment ([b2c36fa](https://github.com/jghauser/papis.nvim/commit/b2c36facad28f8fa53558565b233133a9b573243))
* **utils:** correctly return fallback cite_format ([bc2c43c](https://github.com/jghauser/papis.nvim/commit/bc2c43c4b89ed1ca6c3d6a436e623a40403a0839))
* **utils:** detect windows 32bit systems correctly ([a40e794](https://github.com/jghauser/papis.nvim/commit/a40e7945c4f59db7576f4abc5ecd3903f1037b88))
* **utils:** replace ps option so it works on mac ([3004318](https://github.com/jghauser/papis.nvim/commit/3004318024d1e81d47d1bb791b067ed562971fec))
* **utils:** windows nt detection (fixes [#26](https://github.com/jghauser/papis.nvim/issues/26)) ([3ef6d97](https://github.com/jghauser/papis.nvim/commit/3ef6d97783e9ef3c0b216f6d9f5e96357f6e4694))
