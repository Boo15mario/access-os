#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: build-iso-distrobox.sh [--dry-run]

Build the Access OS ISO using an Arch distrobox container.

Environment overrides:
  DISTROBOX_CMD         Command used to launch distrobox.
                        Default: auto-detect `distrobox`, or `nix shell nixpkgs#distrobox -c distrobox`
  BOX_NAME              Distrobox container name (default: accessos-archiso)
  BOX_IMAGE             Container image (default: docker.io/library/archlinux:latest)
  PROFILE_REL           Archiso profile path relative to repo root (default: ./iso/access-os/releng)
  HOST_BUILDS_ROOT      Build root path (default: /tmp/builds)
  WORK_SUBDIR           Work dir under HOST_BUILDS_ROOT (default: work)
  OUT_SUBDIR            Output dir under HOST_BUILDS_ROOT (default: out)
  CLEAN_BEFORE_BUILD    Remove old work/output dirs before build: 1=enabled (default), 0=disabled
  CONTAINER_PREP_PACKAGES
                        Packages installed in container before build (default: "archiso grub")

Examples:
  ./scripts/build-iso-distrobox.sh
  ./scripts/build-iso-distrobox.sh --dry-run
  BOX_NAME=my-archiso ./scripts/build-iso-distrobox.sh
EOF
}

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
elif [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
elif [[ $# -gt 0 ]]; then
  echo "Error: unknown argument: $1" >&2
  usage >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

DISTROBOX_CMD="${DISTROBOX_CMD:-auto}"
BOX_NAME="${BOX_NAME:-accessos-archiso}"
BOX_IMAGE="${BOX_IMAGE:-docker.io/library/archlinux:latest}"
PROFILE_REL="${PROFILE_REL:-./iso/access-os/releng}"
HOST_BUILDS_ROOT="${HOST_BUILDS_ROOT:-/tmp/builds}"
WORK_SUBDIR="${WORK_SUBDIR:-work}"
OUT_SUBDIR="${OUT_SUBDIR:-out}"
CLEAN_BEFORE_BUILD="${CLEAN_BEFORE_BUILD:-1}"
CONTAINER_PREP_PACKAGES="${CONTAINER_PREP_PACKAGES:-archiso grub}"

if [[ ! -d "${REPO_ROOT}/${PROFILE_REL#./}" ]]; then
  echo "Error: archiso profile not found: ${REPO_ROOT}/${PROFILE_REL#./}" >&2
  exit 1
fi

mkdir -p "${HOST_BUILDS_ROOT}"
HOST_WORK_DIR="${HOST_BUILDS_ROOT%/}/${WORK_SUBDIR}"
HOST_OUT_DIR="${HOST_BUILDS_ROOT%/}/${OUT_SUBDIR}"

if [[ "${DISTROBOX_CMD}" == "auto" ]]; then
  if command -v distrobox >/dev/null 2>&1; then
    DISTROBOX_CMD="distrobox"
  elif command -v nix >/dev/null 2>&1; then
    DISTROBOX_CMD="nix shell nixpkgs#distrobox -c distrobox"
  else
    echo "Error: distrobox not found, and nix is not available for fallback." >&2
    exit 1
  fi
fi

read -r -a distrobox_cmd_arr <<<"${DISTROBOX_CMD}"

run_distrobox() {
  "${distrobox_cmd_arr[@]}" "$@"
}

container_exists=0
if run_distrobox list 2>/dev/null | awk -F'|' 'NR>1 {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | rg -qx "${BOX_NAME}"; then
  container_exists=1
fi

clean_step=""
if [[ "${CLEAN_BEFORE_BUILD}" == "1" ]]; then
  printf -v clean_step 'rm -rf -- %q %q; ' "${HOST_WORK_DIR}" "${HOST_OUT_DIR}"
fi

printf -v container_inner_cmd \
  "set -euo pipefail; cd %q; pacman-key --init; pacman-key --populate archlinux; pacman -Syu --noconfirm %s; %smkarchiso -v -w %q -o %q %q" \
  "${REPO_ROOT}" \
  "${CONTAINER_PREP_PACKAGES}" \
  "${clean_step}" \
  "${HOST_WORK_DIR}" \
  "${HOST_OUT_DIR}" \
  "${PROFILE_REL}"

create_cmd=(create --yes --pull --name "${BOX_NAME}" --image "${BOX_IMAGE}")
enter_cmd=(enter --name "${BOX_NAME}" --additional-flags "--user root" -- bash -lc "${container_inner_cmd}")

echo "Repo root: ${REPO_ROOT}"
echo "Archiso profile: ${PROFILE_REL}"
echo "Build root: ${HOST_BUILDS_ROOT}"
echo "ISO output dir: ${HOST_OUT_DIR}"
echo "Distrobox cmd: ${DISTROBOX_CMD}"
echo "Container name: ${BOX_NAME}"
echo "Container image: ${BOX_IMAGE}"
echo

if [[ "${container_exists}" == "1" ]]; then
  echo "Container exists: ${BOX_NAME}"
else
  echo "Container will be created: ${BOX_NAME}"
fi

echo
echo "Build command:"
printf '  %q' "${distrobox_cmd_arr[@]}" "${enter_cmd[@]}"
echo

if [[ "${DRY_RUN}" == "1" ]]; then
  if [[ "${container_exists}" == "0" ]]; then
    echo
    echo "Create command:"
    printf '  %q' "${distrobox_cmd_arr[@]}" "${create_cmd[@]}"
    echo
  fi
  echo
  echo "Dry run only. No build started."
  exit 0
fi

if [[ "${container_exists}" == "0" ]]; then
  run_distrobox "${create_cmd[@]}"
fi

run_distrobox "${enter_cmd[@]}"

echo
echo "Build finished. Check: ${HOST_OUT_DIR}"
