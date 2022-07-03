# UAV Gaming

## Connecting to the Server

Download [Tailscale](https://tailscale.com), sign in with your favorite method, then accept the invite on Discord.

## Minecraft

- Version: Vanilla 1.19 with [GeyserMC](https://geysermc.org)
- Server Address: 100.70.137.13
    - Use either Vanilla 1.19 or a recent Bedrock/Pocket Edition to connect

### Operations

Run `mcrcon` on the server to use the server console.

## Making Changes

To build the nodes locally, you need `git-crypt` and the key to decrypt the credentials stored in the repo:

```bash
git crypt unlock <key file you received>
nix develop
colmena build
```
