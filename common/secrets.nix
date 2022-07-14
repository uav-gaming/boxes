{ lib, config, ... }:
let
  inherit (lib) types;
in {
  options = {
    uav-gaming.hasSecrets = lib.mkOption {
      type = types.bool;
      default = false;
    };
  };
  config = {
    warnings = lib.optional (!config.uav-gaming.hasSecrets) "Secrets not decrypted. Some configurations are not applied.";
  };
}