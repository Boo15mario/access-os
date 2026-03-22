# Next Steps

This is a living priority list, not a promise.

## Priority 1: Define the golden path
- [ ] choose the first supported install target
- [ ] define the minimum package set for that target
- [ ] confirm how installer profiles map to those packages
- [ ] document the exact build -> boot -> install -> reboot workflow

## Priority 2: Prove integration in a VM
- [ ] publish current package repos
- [ ] build a fresh ISO
- [ ] boot ISO in a VM
- [ ] verify accessibility in the live environment
- [ ] run installer CLI for a full install test
- [ ] reboot and confirm installed system usability

## Priority 3: Make integration explicit
- [ ] document how `access-os-config` is applied
- [ ] document how `access-grub` is integrated
- [ ] document how `access-os-plymouth-theme` is integrated
- [ ] document how artwork and wallpaper assets are packaged or deployed

## Priority 4: Improve repo documentation
- [ ] add README to `access-os-artwork`
- [ ] add README to `access-os-wallpaper`
- [ ] expand integration docs in `access-grub`
- [ ] expand integration docs in `access-os-plymouth-theme`

## Priority 5: Define release quality checks
- [ ] accessibility checklist for live ISO
- [ ] accessibility checklist for installed system
- [ ] package repo health checks
- [ ] installer regression checklist
- [ ] boot/theme verification checklist

## Nice to Have Later
- [ ] automated VM test flow
- [ ] architecture diagrams
- [ ] contributor onboarding docs
- [ ] release checklist and versioning policy
