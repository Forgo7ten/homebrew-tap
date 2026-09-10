#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]
then
  echo "usage: $0 <cask>" >&2
  exit 2
fi

CASK="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

if ! command -v brew >/dev/null 2>&1
then
  echo "error: Homebrew is required" >&2
  exit 1
fi

TAPS_DIR="$(brew --repository)/Library/Taps"
TEMP_OWNER="miclock-fetch-ci"
TEMP_REPO="worktree"
TEMP_OWNER_DIR="${TAPS_DIR}/${TEMP_OWNER}"
TEMP_LINK="${TEMP_OWNER_DIR}/homebrew-${TEMP_REPO}"
TEMP_TAP="${TEMP_OWNER}/${TEMP_REPO}"

# cleanup 仅由 trap 间接调用；ShellCheck 对 trap 调用的函数无法可靠推断。
# shellcheck disable=SC2329
cleanup() {
  brew untrust "${TEMP_TAP}" >/dev/null 2>&1 || true
  rm -f "${TEMP_LINK}"
  rmdir "${TEMP_OWNER_DIR}" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "${TEMP_OWNER_DIR}"
ln -sfn "${REPO}" "${TEMP_LINK}"

export HOMEBREW_DEVELOPER=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

# CI 正在执行当前仓库自身的代码，因此显式信任临时本地 Tap。
brew trust "${TEMP_TAP}"

brew fetch \
  --cask \
  --force \
  --all-platforms \
  "${TEMP_TAP}/${CASK}"
