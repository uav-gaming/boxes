# UAV Gaming

## Connecting to the Server

Download [Tailscale](https://tailscale.com), sign in with your favorite method, then accept the invite on Discord.

## Minecraft

- Version: Fabric 1.19
- Server Address: `100.70.137.13`
- Required Mods:
    - [CC: Restitched](https://modrinth.com/mod/cc-restitched)
- Recommended Mods:
    - [JourneyMap](https://modrinth.com/mod/journeymap)

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

To build the nodes locally, you need `git-crypt` and the key to decrypt the credentials stored in the repo:

```bash
git crypt unlock <key file you received>
nix develop
colmena build
```
