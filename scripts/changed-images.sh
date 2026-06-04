#!/usr/bin/env bash
# 根据 git diff 输出需要重建的镜像名（供 CI matrix 使用）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT}/images.json"
BASE_REF="${1:-origin/main}"

if ! git -C "${ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  jq -c '[.images[] | {name, context, dockerfile, tags}]' "${MANIFEST}"
  exit 0
fi

if ! git -C "${ROOT}" rev-parse "${BASE_REF}" >/dev/null 2>&1; then
  jq -c '[.images[] | {name, context, dockerfile, tags}]' "${MANIFEST}"
  exit 0
fi

mapfile -t changed < <(git -C "${ROOT}" diff --name-only "${BASE_REF}"...HEAD)

if [[ ${#changed[@]} -eq 0 ]]; then
  echo '[]'
  exit 0
fi

# 根目录 manifest / workflow / scripts 变更时重建全部
for f in "${changed[@]}"; do
  case "${f}" in
    images.json|.github/*|scripts/*|README.md)
      jq -c '[.images[] | {name, context, dockerfile, tags}]' "${MANIFEST}"
      exit 0
      ;;
  esac
done

jq -c --argjson paths "$(printf '%s\n' "${changed[@]}" | jq -R . | jq -s .)" '
  .images[]
  | select(. as $img | $paths[] | startswith($img.context + "/"))
  | {name, context, dockerfile, tags}
' "${MANIFEST}" | jq -s '.'
