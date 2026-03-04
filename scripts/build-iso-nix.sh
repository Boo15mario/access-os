#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: build-iso-nix.sh [--dry-run]

Build the Access OS ISO on NixOS by running mkarchiso inside an Arch Linux
container via podman.

Environment overrides:
  PODMAN_CMD        Podman launcher command (default: "sudo podman")
  ARCH_IMAGE        Container image (default: docker.io/library/archlinux:latest)
  PROFILE_REL       Archiso profile path relative to repo root (default: ./iso/access-os/releng)
  HOST_BUILDS_ROOT  Host path mounted to /tmp/builds in container (default: /tmp/builds)
  WORK_SUBDIR       Work dir under /tmp/builds (default: work)
  OUT_SUBDIR        Output dir under /tmp/builds (default: out)

Examples:
  ./scripts/build-iso-nix.sh
  PODMAN_CMD="podman" ./scripts/build-iso-nix.sh
  HOST_BUILDS_ROOT="$HOME/builds" ./scripts/build-iso-nix.sh
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

PODMAN_CMD="${PODMAN_CMD:-sudo podman}"
ARCH_IMAGE="${ARCH_IMAGE:-docker.io/library/archlinux:latest}"
PROFILE_REL="${PROFILE_REL:-./iso/access-os/releng}"
HOST_BUILDS_ROOT="${HOST_BUILDS_ROOT:-/tmp/builds}"
WORK_SUBDIR="${WORK_SUBDIR:-work}"
OUT_SUBDIR="${OUT_SUBDIR:-out}"

if ! command -v nix >/dev/null 2>&1; then
  echo "Error: nix is required but was not found in PATH." >&2
  exit 1
fi

if [[ ! -d "${REPO_ROOT}/${PROFILE_REL#./}" ]]; then
  echo "Error: archiso profile not found: ${REPO_ROOT}/${PROFILE_REL#./}" >&2
  exit 1
fi

mkdir -p "${HOST_BUILDS_ROOT}"

read -r -a podman_cmd_arr <<<"${PODMAN_CMD}"
if [[ "${podman_cmd_arr[0]}" == "sudo" ]] && ! command -v sudo >/dev/null 2>&1; then
  echo "Error: PODMAN_CMD uses sudo but sudo is not available." >&2
  exit 1
fi

container_build_root="/tmp/builds"
container_work_dir="${container_build_root}/${WORK_SUBDIR}"
container_out_dir="${container_build_root}/${OUT_SUBDIR}"

printf -v container_inner_cmd \
  "set -euo pipefail; pacman -Syu --noconfirm archiso; cd /work; mkarchiso -v -w %q -o %q %q" \
  "${container_work_dir}" \
  "${container_out_dir}" \
  "${PROFILE_REL}"

podman_run_args=(run --rm --privileged -i)
if [[ -t 0 && -t 1 ]]; then
  podman_run_args+=(-t)
fi

cmd=(
  nix shell nixpkgs#podman -c
  "${podman_cmd_arr[@]}"
  "${podman_run_args[@]}"
  -v "${REPO_ROOT}:/work"
  -v "${HOST_BUILDS_ROOT}:${container_build_root}"
  "${ARCH_IMAGE}"
  bash -lc "${container_inner_cmd}"
)

echo "Repo root: ${REPO_ROOT}"
echo "Archiso profile: ${PROFILE_REL}"
echo "Host build root: ${HOST_BUILDS_ROOT}"
echo "ISO output dir: ${HOST_BUILDS_ROOT}/${OUT_SUBDIR}"
echo
echo "Command:"
printf '  %q' "${cmd[@]}"
echo

if [[ "${DRY_RUN}" == "1" ]]; then
  echo
  echo "Dry run only. No build started."
  exit 0
fi

"${cmd[@]}"

echo
echo "Build finished. Check: ${HOST_BUILDS_ROOT}/${OUT_SUBDIR}"
