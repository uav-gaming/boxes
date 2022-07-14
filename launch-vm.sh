#!/usr/bin/env bash

# Specify the environment. Either 'dev' or 'prod'.
environment=${1:-dev}

if [ -z "$IN_NIX_SHELL" ]; then
	NIX_PREFIX=("nix" "develop" "--extra-experimental-features" "nix-command flakes" "--command" "--")
else
	NIX_PREFIX=()
fi

cd $(dirname "$0")

# Launch the VM in dev or prod mode.
case $environment in
  prod)
	exec "${NIX_PREFIX[@]}" nixos-shell --flake .#bedrock-mini
    ;;

  dev)
    exec "${NIX_PREFIX[@]}" nixos-shell --flake .#bedrock-mini-dev
    ;;

  *)
    echo "Unknown environement : ${environment}"
    ;;
esac

