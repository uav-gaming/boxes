{ lib, config, ... }:
let
  inherit (lib) types;
in {
  options = {
    uav-gaming.devEnv = lib.mkOption {
      type = types.bool;
      default = true;
    };
  };
  config = {
    warnings = lib.optional (!config.uav-gaming.devEnv) "Using dev environment.";
  };
}