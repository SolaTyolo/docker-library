#!/usr/bin/env bash
# 本地构建并推送到腾讯云 CCR（与 GitHub Actions 使用相同命名规则）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT}/images.json"

REGISTRY="${REGISTRY:-$(jq -r '.registry' "${MANIFEST}")}"
NAMESPACE="${NAMESPACE:-$(jq -r '.namespace' "${MANIFEST}")}"
PLATFORM="${PLATFORM:-linux/amd64}"
IMAGE_NAME="${1:-}"
PUSH="${PUSH:-1}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/build-push.sh <image-name>     # 构建 manifest 中的一项
  ./scripts/build-push.sh --all            # 构建全部
  ./scripts/build-push.sh --list           # 列出可构建镜像

Environment:
  REGISTRY   默认读取 images.json（ccr.ccs.tencentyun.com）
  NAMESPACE  默认 solat（读取 images.json）
  PUSH=0     仅构建，不推送
  PLATFORM   默认 linux/amd64

Examples:
  docker login ccr.ccs.tencentyun.com -u <账号ID> -p <密码>
  ./scripts/build-push.sh postgres
  PUSH=0 ./scripts/build-push.sh golang
EOF
}

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "jq is required" >&2
    exit 1
  }
}

build_row() {
  local row="$1"
  local name context dockerfile tags_json tag ref
  name="$(echo "${row}" | jq -r '.name')"
  context="$(echo "${row}" | jq -r '.context')"
  dockerfile="$(echo "${row}" | jq -r '.dockerfile')"
  tags_json="$(echo "${row}" | jq -c '.tags')"

  while IFS= read -r tag; do
    ref="${REGISTRY}/${NAMESPACE}/${name}:${tag}"
    echo "==> build ${ref} (${context})"
    docker buildx build \
      --platform "${PLATFORM}" \
      -f "${ROOT}/${context}/${dockerfile}" \
      -t "${ref}" \
      "${ROOT}/${context}" \
      $([[ "${PUSH}" == "1" ]] && echo --push || echo --load)
  done < <(echo "${tags_json}" | jq -r '.[]')
}

build_one() {
  local name="$1"
  local count=0
  while IFS= read -r row; do
    build_row "${row}"
    count=$((count + 1))
  done < <(jq -c --arg n "${name}" '.images[] | select(.name == $n)' "${MANIFEST}")
  if [[ "${count}" -eq 0 ]]; then
    echo "unknown image: ${name}" >&2
    exit 1
  fi
}

list_images() {
  jq -r '.images[] | "\(.name) (\(.tags[0]))"' "${MANIFEST}"
}

main() {
  require_jq
  case "${IMAGE_NAME:-}" in
    -h|--help|help|"")
      usage
      exit 0
      ;;
    --list)
      list_images
      exit 0
      ;;
    --all)
      while IFS= read -r row; do
        build_row "${row}"
      done < <(jq -c '.images[]' "${MANIFEST}")
      ;;
    *)
      build_one "${IMAGE_NAME}"
      ;;
  esac
}

main "$@"
