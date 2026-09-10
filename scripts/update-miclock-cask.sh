#!/usr/bin/env bash

# 根据 Forgo7ten/MicLock 指定或最新 stable GitHub Release
# 更新 Casks/miclock.rb 中的版本号和两个架构的 SHA256。
#
# 默认：
#
#   SOURCE_REPOSITORY=Forgo7ten/MicLock
#   CASK_PATH=<repo>/Casks/miclock.rb
#
# 可选环境变量：
#
#   GH_TOKEN
#       GitHub API Token。
#       对公开仓库不是必需，但在 GitHub Actions 中建议提供。
#
#   RELEASE_TAG
#       可选。指定时精确更新该 stable Release，例如 v1.2.3。
#       未指定时查询 GitHub 最新 stable Release。
#
#   SOURCE_REPOSITORY
#       MicLock 源仓库。
#
#   CASK_PATH
#       要修改的 Cask 文件路径。
#
# 本脚本只负责修改 Cask，不负责 git commit / git push。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REWRITE_SCRIPT="${SCRIPT_DIR}/rewrite-miclock-cask.py"

SOURCE_REPOSITORY="${SOURCE_REPOSITORY:-Forgo7ten/MicLock}"
CASK_PATH="${CASK_PATH:-${REPO_ROOT}/Casks/miclock.rb}"

# ------------------------------------------------------------
# 0. 基础检查
# ------------------------------------------------------------

for command_name in curl jq python3 cmp
do
  if ! command -v "${command_name}" >/dev/null 2>&1
  then
    echo "error: Required command not found: ${command_name}" >&2
    exit 1
  fi
done

if [[ ! -f "${CASK_PATH}" ]]
then
  echo "error: Cask file does not exist: ${CASK_PATH}" >&2
  exit 1
fi

if [[ ! -f "${REWRITE_SCRIPT}" ]]
then
  echo "error: Cask rewrite helper does not exist: ${REWRITE_SCRIPT}" >&2
  exit 1
fi

release_json="$(mktemp)"
updated_cask="$(mktemp)"

trap 'rm -f "${release_json}" "${updated_cask}"' EXIT

requested_tag="${RELEASE_TAG:-}"

if [[ -n "${requested_tag}" ]]
then
  if [[ ! "${requested_tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
  then
    echo "error: RELEASE_TAG must use vMAJOR.MINOR.PATCH format: ${requested_tag}" >&2
    exit 1
  fi

  release_api="https://api.github.com/repos/${SOURCE_REPOSITORY}/releases/tags/${requested_tag}"
else
  release_api="https://api.github.com/repos/${SOURCE_REPOSITORY}/releases/latest"
fi

# ------------------------------------------------------------
# 1. 获取指定或最新 stable GitHub Release
# ------------------------------------------------------------

curl_args=(
  --silent
  --show-error
  --location
  --header "Accept: application/vnd.github+json"
  --header "X-GitHub-Api-Version: 2026-03-10"
)

if [[ -n "${GH_TOKEN:-}" ]]
then
  curl_args+=(
    --header "Authorization: Bearer ${GH_TOKEN}"
  )
fi

http_status="$(
  curl \
    "${curl_args[@]}" \
    --write-out '%{http_code}' \
    --output "${release_json}" \
    "${release_api}"
)" || {
  echo "error: Failed to query the MicLock releases API" >&2
  exit 1
}

if [[ "${http_status}" == "404" ]]
then
  if [[ -n "${requested_tag}" ]]
  then
    echo "error: Requested MicLock release does not exist: ${requested_tag}" >&2
    exit 1
  else
    echo "No stable MicLock release is available; leaving the Cask unchanged."
    exit 0
  fi
fi

if [[ "${http_status}" != "200" ]]
then
  echo "error: MicLock releases API returned HTTP ${http_status}" >&2
  exit 1
fi

# ------------------------------------------------------------
# 2. 解析版本
# ------------------------------------------------------------

tag="$(jq -r '.tag_name // empty' "${release_json}")"

if [[ ! "${tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  echo "error: MicLock release tag is not a stable semver tag: ${tag:-<empty>}" >&2
  exit 1
fi

if [[ -n "${requested_tag}" && "${tag}" != "${requested_tag}" ]]
then
  echo "error: Requested ${requested_tag}, but GitHub returned ${tag}" >&2
  exit 1
fi

draft="$(jq -r '.draft // false' "${release_json}")"
if [[ "${draft}" == "true" ]]
then
  echo "error: Refusing to update from draft release ${tag}" >&2
  exit 1
fi

prerelease="$(jq -r '.prerelease // false' "${release_json}")"
if [[ "${prerelease}" == "true" ]]
then
  echo "error: Refusing to update from prerelease ${tag}" >&2
  exit 1
fi

version="${tag#v}"

arm_archive="MicLock-v${version}-arm64.zip"
intel_archive="MicLock-v${version}-x86_64.zip"

echo "Latest MicLock release: ${tag}"
echo "ARM64 asset: ${arm_archive}"
echo "Intel asset: ${intel_archive}"

# ------------------------------------------------------------
# 3. 从 GitHub Release Asset digest 获取 SHA256
# ------------------------------------------------------------

digest_for() {
  local wanted="$1"
  local asset_count

  asset_count="$(
    jq \
      --arg name "${wanted}" \
      '[
        .assets[]?
        | select(
            .name == $name
            and .state == "uploaded"
            and (.size // 0) > 0
          )
      ] | length' \
      "${release_json}"
  )"

  if [[ "${asset_count}" != "1" ]]
  then
    echo "error: Expected exactly one uploaded asset named ${wanted}, found ${asset_count}" >&2
    return 1
  fi

  jq \
    --raw-output \
    --arg name "${wanted}" \
    '
      [
        .assets[]?
        | select(
            .name == $name
            and .state == "uploaded"
            and (.size // 0) > 0
          )
        | .digest
      ][0] // empty
    ' \
    "${release_json}"
}

arm_digest="$(digest_for "${arm_archive}")"
intel_digest="$(digest_for "${intel_archive}")"

# ------------------------------------------------------------
# 4. 校验 digest
# ------------------------------------------------------------

if [[ ! "${arm_digest}" =~ ^sha256:[0-9A-Fa-f]{64}$ ]]
then
  echo "error: Invalid or missing GitHub SHA-256 digest for ${arm_archive}: ${arm_digest:-<empty>}" >&2
  exit 1
fi

if [[ ! "${intel_digest}" =~ ^sha256:[0-9A-Fa-f]{64}$ ]]
then
  echo "error: Invalid or missing GitHub SHA-256 digest for ${intel_archive}: ${intel_digest:-<empty>}" >&2
  exit 1
fi

arm_sha="${arm_digest#sha256:}"
intel_sha="${intel_digest#sha256:}"

echo "ARM64 SHA256: ${arm_sha}"
echo "Intel SHA256: ${intel_sha}"

# ------------------------------------------------------------
# 5. 更新 Cask
#
# 将文本重写逻辑放到独立 Python helper，避免 Homebrew 的 shell formatter
# 把 heredoc 中的 Python `if` 误识别为 shell `if`。
# ------------------------------------------------------------

python3 "${REWRITE_SCRIPT}" \
  "${CASK_PATH}" \
  "${updated_cask}" \
  "${version}" \
  "${arm_sha}" \
  "${intel_sha}"

# ------------------------------------------------------------
# 6. 仅在内容发生变化时覆盖 Cask
# ------------------------------------------------------------

if cmp -s "${updated_cask}" "${CASK_PATH}"
then
  echo "MicLock Cask is already up to date at ${version}."
  exit 0
fi

mv "${updated_cask}" "${CASK_PATH}"

echo "Updated MicLock Cask to ${version}."
