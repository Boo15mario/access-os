# Build and Release Flow

This document describes the current intended Access OS flow based on the existing repositories.

## Current Intended Flow

### 1. Package build and publish
Repository: `access-os-packages`

Goal:
- build `access-os-core` and `access-os-extra`
- publish package files to GitHub Releases
- publish repo metadata to GitHub Pages

Primary command:

```bash
./scripts/publish.sh
```

### 2. Refresh package availability
Repository: `access-os`

Goal:
- ensure ISO build points at current package repositories
- verify package repos are reachable before ISO build

Notes:
- `access-os` expects the package repositories to already exist and be reachable.

### 3. Build the ISO
Repository: `access-os`

Possible entrypoints:

```bash
./build.sh
./scripts/build-iso-distrobox.sh
./scripts/build-iso-nix.sh
```

### 4. Boot the live environment
Goal:
- confirm ISO boots
- confirm accessibility path is usable
- confirm installer is available

### 5. Run installer
Repository: `access-os-installer`

Preferred development/test path:
- use the CLI installer first for accessible iteration
- use `--dry-run` during development when possible

### 6. Reboot into installed system
Goal:
- verify the installed system boots cleanly
- confirm key accessibility defaults still work after install

## Minimum Golden Path

The first reliable milestone should be one complete path:

1. publish packages
2. build ISO
3. boot ISO in a VM
4. launch installer CLI
5. install to VM disk
6. reboot successfully
7. confirm system is usable with keyboard and speech

## Current Gaps to Document or Confirm

- How `access-os-config` is injected into the live ISO and/or installed system
- How installer profiles map to package repositories and package groups
- How GRUB, Plymouth, wallpaper, and artwork repos are integrated into packages or install steps
- Which components are mandatory for the first supported release versus optional later polish

## Suggested Validation Checklist

- package repos reachable
- ISO build completes
- live ISO boots in VM
- speech/audio path works in live session
- installer CLI works with screen reader-friendly interaction
- install completes without manual repair
- GRUB theme appears
- Plymouth theme appears if enabled
- installed system reaches a usable login/session state
