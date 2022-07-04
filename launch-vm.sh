#!/usr/bin/env bash

if [ -z "$IN_NIX_SHELL" ]; then
	NIX_PREFIX=("nix" "develop" "--extra-experimental-features" "nix-command flakes" "--command" "--")
else
	NIX_PREFIX=()
fi

cd $(dirname "$0")
exec "${NIX_PREFIX[@]}" nixos-shell --flake .#bedrock-mini
