# UAV Gaming

[![Build](https://github.com/uav-gaming/boxes/actions/workflows/build.yml/badge.svg)](https://github.com/uav-gaming/boxes/actions/workflows/build.yml)
[![Deploy](https://github.com/uav-gaming/boxes/actions/workflows/deploy.yml/badge.svg)](https://github.com/uav-gaming/boxes/actions/workflows/deploy.yml)

## Connecting to the Server

Download [Tailscale](https://tailscale.com), sign in with your favorite method, then accept the invite on Discord.

## Minecraft

- Version: Fabric 1.19
- Server Address: `100.70.137.13`(requires tailscale)
    - Dynmap Address: http://100.70.137.13:8123/
    - Seed: `7846673820795225185`
- Required Mods:
    - [Fabric API](https://modrinth.com/mod/fabric-api)
    - [CC: Restitched](https://modrinth.com/mod/cc-restitched)
    - [Applied Energistics 2(AE2)](https://modrinth.com/mod/ae2)
- Recommended Mods:
    - [JourneyMap](https://modrinth.com/mod/journeymap)
    - [Roughly Enough Items (REI)](https://modrinth.com/mod/roughly-enough-items)

### Operations

Run `mcrcon` on the server to use the server console.

## Making Changes

The servers run [NixOS](https://nixos.org/manual/nixos/unstable) and are deployed with [Colmena](https://github.com/zhaofengli/colmena).

Install [Nix](https://nixos.org/download.html), then run `nix-shell` to enter the shell environment with all dependencies.

### Local VM

To start the server locally in a VM, run `./launch-vm.sh`.
You can then point your Minecraft client at `localhost`.
To access the server console, log in as `root` with no password then run `mcrcon`.

The first start can take a while. Use `journalctl -fu minecraft-server` to watch the progress.

### Colmena

To build the production nodes locally, you need `git-crypt` and the key to decrypt the credentials stored in the repo:

```bash
git crypt unlock <key file you received>
nix develop
colmena build
```
