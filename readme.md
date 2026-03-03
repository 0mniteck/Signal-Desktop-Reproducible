[![image](https://github.com/user-attachments/assets/202613c2-97b8-4b54-b72c-6f8e110f0ff4)](https://signal.org)

# Signal Desktop Builder For Debian:arm64
### [signal-desktop_7.68.0_arm64.deb](https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/7.68.x/builds/release/signal-desktop_7.68.0_arm64.deb)

This project reproducibly builds Signal Desktop for Debian Trixie on Arm64, currently targeting tag `7.68.x`

> Now with an optional update client: [`auto-update-cron.sh`](https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/master/auto-update-cron.sh)

This is the latest release: [`builds/release/signal-desktop_7.68.0_arm64.deb`](https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/7.68.x/builds/release/signal-desktop_7.68.0_arm64.deb)

Sha512Sum: [`Results/release.sha512sum`](https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/7.68.x/Results/release.sha512sum)

> ### Full chain/("Full Scope") SBOMs and Attestations
>
> Firmware SBOM's: [`U-Boot:/Results`](https://github.com/0mniteck/U-Boot/tree/v2025.04%2Bv2.12.1%2Bv4.5.0/Results)
>
> System SBOM: [`Results/ubuntu.spdx.json`](https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/7.68.x/Results/ubuntu.spdx.json)
>
> - [x] Grype Scan: [`Results/ubuntu.grype.status`](https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/7.68.x/Results/ubuntu.grype.status)(https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/708b3a5e538546e7c23cd26c5fa3d1260ce7d42d/Results/ubuntu.grype.status#L1-L3)
>
> Docker SBOM: [`Results/signal.spdx.json`](https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/7.68.x/Results/signal.spdx.json)
>
> - [x] Grype Scan: [`Results/signal.grype.status`](https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/7.68.x/Results/signal.grype.status)(https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/71cac5a24f2abf71af5fdefb0b08cea8a391b91d/Results/signal.grype.status#L1-L3)

0mniteck's Current GPG Key ID: `287EE837E6ED2DD3`

<sup><sup>*Vigilant Mode is on for this repo so all remote pushes/tags should be signed with a verified key.</sup></sup>

## Build Instructions/Usage:

### Usage:

> Installation:
> 1. [Download the `.deb`](https://github.com/0mniteck/Signal-Desktop-Reproducible/raw/7.68.x/builds/release/signal-desktop_7.68.0_arm64.deb) to your device
> 2. verify the sha512sum
> [[Current sha512sum]](https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/7.68.x/Results/release.sha512sum#L2)
> (https://github.com/0mniteck/Signal-Desktop-Reproducible/blob/708b3a5e538546e7c23cd26c5fa3d1260ce7d42d/Results/release.sha512sum#L2)
> - ```sha512sum signal-desktop_7.68.0_arm64.deb```
> 3. install:
> - ```pkexec apt install ./signal-desktop_7.68.0_arm64.deb```

### Optional Installer/Updater:

Install updater `auto-update-cron.sh` by running:

```
sudo su && \
curl -sSL https://raw.githubusercontent.com/0mniteck/Signal-Desktop-Reproducible/master/auto-update-cron.sh | bash
```

### Build:

>  buildscript.sh:
>  - -c {Cross Compile: <ins>Y</ins>es/no}
>  - -d {Date: <ins>S</ins>ource_date_epoch/today}
>  - -i {Increment: .version}
>  - -m {Mount Luks partition: mmcblk1p1}
>  - -p {Push-branch: branch}
>  - -r {Release-tag: tagname}
>  - -t {run-Tests: yes/<ins>N<ins>o}

A. First build and push the upcoming branch:

```
git clone --depth 1 https://github.com/$REPO/Signal-Desktop-Reproducible.git && \
cd Signal-Desktop-Reproducible && \
./buildscript.sh -i'.01' -p'7.xx.x' -d'today'
```
---

B. Then rebuild the current branch and release:

```
git clone --depth 1 git@github.com:$REPO/Signal-Desktop-Reproducible.git -b 7.xx.x && \
cd Signal-Desktop-Reproducible && \
./buildscript.sh -p'main' -r'7.xx.0'
```
---

C. To build a past release (7.90.0+) for reproducibility:

```
git clone --depth 1 git@github.com:0mniteck/Signal-Desktop-Reproducible.git -b 7.xx.x && \
cd Signal-Desktop-Reproducible && \
./buildscript.sh
```

## Current Status:‎‎‏‏‎‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎[![CI](https://github.com/signalapp/Signal-Desktop/actions/workflows/ci.yml/badge.svg?branch=7.68.x)](https://github.com/signalapp/Signal-Desktop/actions/workflows/ci.yml)<sub><sup> signalapp/Signal-Desktop</sup></sub>

* [x] Built with [0mniteck/debian-slim:latest](https://hub.docker.com/r/0mniteck)
* [x] Signal Desktop builds
* [x] Auto-Update script
* [x] Reproducible builds
* [x] Generate/Scan SBOM at buildtime

## Release Cycle:

Currently building upstream releases twice to improve reproducibility/reliability:

`build/release to branch 7.xx.x` --> `test on hardware, document, pull request` --> `build/release to master branch`

## See also:
* [The Sovereignty Ephemerality Reproducibility (SER) framework](https://omniteck.com/?p=1104)
* https://snapshot.debian.org
* https://hub.docker.com/_/debian/tags
* https://hub.docker.com/r/0mniteck/tags
* https://github.com/signalapp/Signal-Desktop/blob/main/reproducible-builds/README.md
* https://github.com/signalapp/Signal-Desktop/blob/development/CONTRIBUTING.md
