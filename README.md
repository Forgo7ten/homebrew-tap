# Homebrew Tap

这是 `Forgo7ten` 的个人 Homebrew Tap，用于维护多个 Formula 和 Cask。仓库名称使用 Homebrew 约定的 `homebrew-tap`，用户可以通过 `Forgo7ten/tap` 引用它。

## 安装

```zsh
brew tap Forgo7ten/tap
brew trust Forgo7ten/tap
```

`brew trust Forgo7ten/tap` 表示信任本 Tap 中当前及未来的 Formula、Cask
和外部命令，适合将本仓库作为一个整体长期使用的场景。

## Formulae

当前暂无 Formula。

## Casks

| Cask | 说明 |
| --- | --- |
| `miclock` | 锁定 macOS 首选音频输入设备 |

### miclock

```zsh
brew install --cask Forgo7ten/tap/miclock
```

`miclock` 会根据 Mac 的 CPU 架构选择对应的 Release 产物：Apple Silicon 使用 `arm64`，Intel 使用 `x86_64`。安装后的应用名称为 `MicLock.app`。

## 文档

- [MicLock Cask 更新说明](docs/miclock-cask.md)

## 仓库结构

```text
homebrew-tap/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── update-miclock.yml
├── Casks/
│   └── miclock.rb
├── docs/
│   └── miclock-cask.md
└── scripts/
    ├── check-cask-fetch.sh
    ├── check-tap-syntax.sh
    ├── rewrite-miclock-cask.py
    └── update-miclock-cask.sh
```

`scripts/update-miclock-cask.sh` 在自动同步时精确使用 MicLock Release 传入的 tag，
手动运行时则根据最新稳定 GitHub Release 更新 Cask 的版本和两个架构的 SHA256。
稳定版 MicLock Release 会自动触发该更新流程，也可以在 Actions 中手动运行
`Update MicLock Cask`。
提交 Cask 前会运行 `scripts/check-tap-syntax.sh`，执行 `brew style`、`brew readall`
和 `brew audit`，随后由 `scripts/check-cask-fetch.sh` 通过 Cask 实际获取所有架构的
Release 产物。
普通 push / pull request 也会运行 Tap 语法校验。

新增 Formula 时创建 `Formula/` 目录；新增 Formula 或 Cask 后，将文件放入对应目录，并在本 README 的对应列表中补充说明。
