#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT/kustomize/templates"
BASE_TEMPLATE="$TEMPLATE_DIR/overlay.yaml.tpl"

app_instance_suffix() {
  local namespace="$1"
  case "$namespace" in
    bym-oslo-kommune-no)
      printf '%s' "$namespace"
      ;;
    *)
      printf '%s' "${namespace//-/_}"
      ;;
  esac
}

while IFS= read -r file; do
  rel="${file#"$ROOT/kustomize/overlays/"}"
  dir="$(dirname "$rel")"

  namespace="${dir%%/*}"

  export NAMESPACE="$namespace"
  export ORG_ID="${namespace//-/.}"
  export APP_INSTANCE="fint-flyt-integration-configuration-service_$(app_instance_suffix "$namespace")"

  tmp="$(mktemp)"
  envsubst < "$BASE_TEMPLATE" > "$tmp"
  mv "$tmp" "$file"
done < <(find "$ROOT/kustomize/overlays" -name kustomization.yaml -print | sort)
