# Access OS Stack Overview

Access OS is an accessible Arch Linux based distribution focused on blind and visually impaired users.

## Project Repositories

### `access-os`
Top-level distro repository.

Responsibilities:
- ISO build orchestration
- archiso layout and build entrypoints
- top-level documentation for how the distro is assembled

### `access-os-packages`
Package repository and publishing system.

Responsibilities:
- maintain `access-os-core`
- maintain `access-os-extra`
- build package artifacts locally on Arch
- publish package databases to GitHub Pages
- publish package files to GitHub Releases

### `access-os-config`
System configuration defaults for installed/live systems.

Likely responsibilities:
- pacman config
- initramfs/dracut or mkinitcpio defaults
- sudo/system environment defaults
- desktop/session defaults
- any distro-wide config files that should ship with Access OS

### `access-os-installer`
Installer implementation, with accessibility as a primary goal.

Responsibilities:
- line-oriented CLI installer for screen reader friendliness
- GTK installer for graphical sessions
- shared install backend
- install profile definitions

### `access-os-artwork`
Branding and shared visual assets.

Responsibilities:
- logos
- default artwork
- reusable theme assets

### `access-os-wallpaper`
Wallpaper asset repository.

Responsibilities:
- default wallpapers
- wallpaper selection candidates for the distro

### `access-os-plymouth-theme`
Boot splash theme.

Responsibilities:
- Plymouth theme assets and config
- install/update steps for Plymouth integration

### `access-grub`
GRUB theme.

Responsibilities:
- bootloader theme assets
- theme config for GRUB

## Intended Relationship Between Repos

The rough pipeline appears to be:

1. Build and publish packages from `access-os-packages`
2. Use those package repositories when building the ISO in `access-os`
3. Include distro defaults from `access-os-config`
4. Ship and run `access-os-installer` from the live environment
5. Apply branding/theme assets from artwork, Plymouth, GRUB, and wallpaper repos

## Architecture Notes

Current strengths:
- clean separation of concerns
- installer accessibility is a first-class concern
- package publishing is separated from ISO generation
- branding/theming is split into dedicated components

Current risks:
- integration drift between installer, packages, config, and ISO build
- unclear source of truth for how visual/theme repos become installed packages
- some repos need stronger README-level explanation and integration notes

## Open Questions

- How exactly is `access-os-config` consumed during ISO build and install?
- Which visual/theme repos are packaged versus copied directly?
- What is the canonical first supported install target?
- What accessibility behavior is guaranteed at boot, installer, login, and first desktop launch?
- Which repo is the source of truth for package groups used by installer profiles?
