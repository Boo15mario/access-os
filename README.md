# access-os

Access OS is an accessible Arch Linux based distribution for blind and visually impaired users.

## Package repositories

Access OS uses two pacman repositories published from the `access-os-packages` project:

- `access-os-core` for Access OS maintained packages
- `access-os-extra` for selected AUR packages and preserved AUR snapshots

Those repositories are configured in:

- `iso/access-os/releng/pacman.conf`
- `iso/access-os/releng/airootfs/etc/pacman.conf`

Repository metadata is served from GitHub Pages and package files are served from GitHub Releases.

## Build and publish model

Package building no longer happens in GitHub Actions.

The expected workflow is:

1. Build and publish packages from a local Arch Linux system in `access-os-packages`
2. Refresh the package repositories with `./scripts/publish-local.sh`
3. Build the Access OS ISO from this repository after the package repos are updated

The minimum Arch packages and local publishing steps are documented in `access-os-packages/README.md`.

## Building the ISO

This repository contains a few build entrypoints:

- `build.sh` for direct local `mkarchiso` usage
- `scripts/build-iso-distrobox.sh` for distrobox-based builds
- `scripts/build-iso-nix.sh` for NixOS/podman-based builds

The ISO build expects the Access OS pacman repositories to already be populated and reachable.
