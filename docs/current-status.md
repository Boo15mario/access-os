# Current Status

_Last updated: 2026-03-19_

## What Exists

### Core project structure
- `access-os` for ISO build orchestration
- `access-os-packages` for package build/publish workflows
- `access-os-config` for distro/system configuration
- `access-os-installer` for CLI + GTK install experience
- `access-os-artwork`, `access-os-wallpaper`, `access-os-plymouth-theme`, and `access-grub` for branding and boot visuals

### Strengths
- repo split is logical and maintainable
- installer accessibility is already treated as a first-class concern
- package publishing is separated from ISO building
- project scope is coherent: distro, installer, repos, and branding are all represented

### Current documentation state
- top-level repo READMEs exist for several major repos
- some component repos still need integration-oriented documentation
- there was no central docs hub in `access-os` before this docs directory was added

## What Seems In Progress

- defining the distro build and publish flow
- building an accessible installer experience
- organizing package repos for long-term maintainability
- building a branded boot/user experience

## Known Documentation Gaps

- no single canonical architecture doc before now
- no single project-level roadmap in one place
- incomplete explanation of how config and theme repos feed into the final ISO/install
- unclear first-release definition or milestone breakdown

## Current Working Assumption

The most valuable next milestone is a complete end-to-end VM install path that proves the existing pieces work together.

## TBD / Needs Confirmation

- first officially supported desktop/session target
- speech stack and accessibility guarantees across boot, install, login, and first run
- packaging path for Plymouth, GRUB theme, artwork, and wallpaper assets
- final source of truth for installer package profiles
