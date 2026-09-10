# MicLock Cask 更新说明

`.github/workflows/update-miclock.yml` 负责 `miclock` 的自动更新、验证和提交。它支持两种触发方式：

- `repository_dispatch`：`Forgo7ten/MicLock` 发布 stable Release 后自动发送
  `miclock-release` 事件；workflow 将 `client_payload.tag` 作为 `RELEASE_TAG`
  传给更新脚本，精确处理该 Release；
- `workflow_dispatch`：在 GitHub Actions 页面手动运行，作为人工更新和失败恢复入口。
  此时不指定 `RELEASE_TAG`，脚本查询最新 stable Release。

`scripts/update-miclock-cask.sh` 负责实际的 Cask 更新逻辑。设置 `RELEASE_TAG`
时，它查询 `Forgo7ten/MicLock` 对应 tag 的 stable Release；未设置时查询最新
stable Release。脚本只接受 `vMAJOR.MINOR.PATCH` 格式的版本，拒绝 draft 和
prerelease，并要求同时存在已上传且非空的 arm64 与 x86_64 ZIP。
脚本从 GitHub Release Asset 的 `digest` 字段读取两个 ZIP 的 SHA256。

更新完成后，workflow 在提交前运行 `scripts/check-tap-syntax.sh`。该脚本把当前
working tree 临时映射为 Homebrew Tap，并依次执行：

- `brew style`
- `brew readall --aliases --os=all --arch=all`
- `brew audit --except=installed --tap`

任何检查失败都会阻止 commit/push。若 Cask 内容没有变化，则不会产生提交。

静态校验完成后，workflow 还会运行：

```bash
./scripts/check-cask-fetch.sh miclock
```

该脚本把当前 working tree 临时映射为 Homebrew Tap，并执行
`brew fetch --cask --force --all-platforms`。因此会通过 Cask 自身的 URL 和
checksum 实际获取并验证 arm64 与 x86_64 Release 产物；失败会阻止 commit/push。

脚本只更新 `Casks/miclock.rb` 中的 `version`、arm64 SHA256 和 x86_64 SHA256；Release URL 使用 `#{version}` 与 `#{arch}` 自动展开，其他 Cask 元数据保持不变。workflow 将本 Tap 仓库的 `GITHUB_TOKEN` 传给脚本，并且只在内容变化时提交。若推送被仓库设置拒绝，请在 **Settings → Actions → General → Workflow permissions** 开启 **Read and write permissions**。

也可以在仓库根目录独立运行更新脚本：

```bash
./scripts/update-miclock-cask.sh
```

精确测试某个 stable Release：

```bash
RELEASE_TAG=vX.Y.Z ./scripts/update-miclock-cask.sh
```

macOS 本地完整验证：

```bash
./scripts/check-tap-syntax.sh
./scripts/check-cask-fetch.sh miclock
```

Linux 开发机可以运行更新脚本、Bash/Python 静态检查和 `actionlint`，但不能把
Homebrew Cask 的 `brew style`、`brew readall`、`brew audit`、`brew fetch --cask`
结果作为最终验证。Linux 上修改完成后，应通过针对 `main` 的 Pull Request 触发
`.github/workflows/ci.yml`，以 macOS runner 的结果为最终准入条件。

公开仓库允许不设置 `GH_TOKEN` 的匿名请求。脚本还支持用 `RELEASE_TAG` 精确指定
stable Release、用 `SOURCE_REPOSITORY` 覆盖源仓库，以及用 `CASK_PATH` 指向临时
或其他 Cask 文件。
