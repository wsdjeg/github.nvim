# Changelog

## [0.2.0](https://github.com/wsdjeg/github.nvim/compare/v0.1.0...v0.2.0) (2026-07-20)


### ⚠ BREAKING CHANGES

* Token is no longer read from GITHUB_TOKEN env var. Use require('github').setup({ token = 'your-token' }) instead.

### Features

* **actions:** add download_job_logs for per-job log download ([9249e27](https://github.com/wsdjeg/github.nvim/commit/9249e27c9cf8b190c2ad817fec3b7705010589e8))
* **actions:** add get_job_logs for parsed step-by-step job logs ([66d40d9](https://github.com/wsdjeg/github.nvim/commit/66d40d91cbae993a96fb0efd0f9a2b3234c84a12))
* add function to update secrets ([d0cd7b1](https://github.com/wsdjeg/github.nvim/commit/d0cd7b1c7e332eb408ac0c018b4bcccd2af3b39e))
* add GitHub Actions workflows and runs module ([d058a69](https://github.com/wsdjeg/github.nvim/commit/d058a69a5641ff40fb37d2f298f6f7ecc4d10f7d))
* add main entry point and setup configuration ([a106f55](https://github.com/wsdjeg/github.nvim/commit/a106f55660ac27b8baac4ecb2f404a84eec6bbcd))
* add pull request management module ([b3c36bf](https://github.com/wsdjeg/github.nvim/commit/b3c36bfdbee98ea6b985d80271456ada4388ffd3))
* add releases management module ([adb38d5](https://github.com/wsdjeg/github.nvim/commit/adb38d592090bdbaaa7496defa99e27717eb9541))
* add search module for code, repos, and issues ([b853383](https://github.com/wsdjeg/github.nvim/commit/b853383efdd68b92c8e58d55a32423cffa6bbcc6))
* add test suite and update GitHub API modules ([219aafe](https://github.com/wsdjeg/github.nvim/commit/219aafe5aace7f902cebeb6a8958189e109ce24e))
* add update-repository api ([2f94b9d](https://github.com/wsdjeg/github.nvim/commit/2f94b9d748031216007b2b0c4a97d25f08111c4a))
* add users and organizations module ([971d9f3](https://github.com/wsdjeg/github.nvim/commit/971d9f3d42832354860debe4b45d3fad7de8679a))
* **tools:** add github_action tool for chat.nvim integration ([dbd21ae](https://github.com/wsdjeg/github.nvim/commit/dbd21aed4efd712558ea381e0564bb1fb8b246fd))


### Bug Fixes

* update repository api url ([ff83afc](https://github.com/wsdjeg/github.nvim/commit/ff83afc8ca91848846a4c95f79f1ac96dec2a83a))


### Code Refactoring

* **chat:** use async API for github_action tool ([856a15f](https://github.com/wsdjeg/github.nvim/commit/856a15f3548b80181c29e7da77163039e80af330))
* use setup token instead of environment variable ([213ff91](https://github.com/wsdjeg/github.nvim/commit/213ff91306093f6afad05790fb669866836b88ad))


### Documentation

* add AGENTS.md project assistant guide ([378e238](https://github.com/wsdjeg/github.nvim/commit/378e2382177ff02ce302e7a95616cde786bbbdc1))
* update readme ([0f392b2](https://github.com/wsdjeg/github.nvim/commit/0f392b210605e499b534763e76cd13f48546fc07))
* update README style to match picker.nvim ([530716e](https://github.com/wsdjeg/github.nvim/commit/530716e1050ea876e9fad96c439c76df2b12380b))
* update README with async API docs and fix org method name ([745a56f](https://github.com/wsdjeg/github.nvim/commit/745a56f2bbf809538e990eeb873d117e49e47e20))
* update README with new modules and usage ([b9e444d](https://github.com/wsdjeg/github.nvim/commit/b9e444d49da1fa2f78884bea0c6b92b2f3e143fa))


### Tests

* fix testPendingCountAfterAsyncRequest to avoid mock job sync issue ([64ab6b6](https://github.com/wsdjeg/github.nvim/commit/64ab6b6cd6cd1a63de6eb743e86684624b024221))

## 0.1.0 (2025-11-24)


### Features

* add get issue api ([ad31fc4](https://github.com/wsdjeg/github.nvim/commit/ad31fc4d5698ea0f725a52d6b3905514dd3d8fab))
* implement rulesets apis ([b86f5d4](https://github.com/wsdjeg/github.nvim/commit/b86f5d4eed355528cdf7a149a7108b92e4544ac6))


### Bug Fixes

* add luarocks ([e5dbd06](https://github.com/wsdjeg/github.nvim/commit/e5dbd06fa5abdf4e449fb1cfa8165ebd1ba04db7))
