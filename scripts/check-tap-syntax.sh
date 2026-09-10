#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO="${1:-${DEFAULT_REPO}}"

if [[ $# -gt 1 ]]
then
  echo "usage: $0 [repo]" >&2
  exit 2
fi

if [[ ! -d "${REPO}" ]]
then
  echo "error: repository directory does not exist: ${REPO}" >&2
  exit 1
fi

REPO="$(cd "${REPO}" && pwd)"

if ! command -v brew >/dev/null 2>&1
then
  echo "error: Homebrew is required" >&2
  exit 1
fi

TAPS_DIR="$(brew --repository)/Library/Taps"
TEMP_OWNER="miclock-ci"
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

# readall/audit 需要实际加载当前临时 Tap；Homebrew 6 默认要求显式 trust。
brew trust "${TEMP_TAP}"

failed=0

brew style "${TEMP_TAP}" || failed=1
brew readall --aliases --os=all --arch=all "${TEMP_TAP}" || failed=1
brew audit --except=installed --tap "${TEMP_TAP}" || failed=1

exit "${failed}"
