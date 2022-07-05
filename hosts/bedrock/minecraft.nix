{ lib, pkgs, config, ... }:

with builtins;

let
  # Java Edition
  javaPort = 25565;
  package = pkgs.fabricServers.fabric-1_19;

  # Bedrock/Pocket (GeyserMC)
  bedrockPort = 19132;

  # Fabric mods
  mods = {
    cc-restitched = pkgs.fetchurl {
      url = "https://github.com/cc-tweaked/cc-restitched/releases/download/v1.19-1.101.0-ccr/cc-restitched-1.101.0.jar";
      sha256 = "sha256-7g5xfUjwOz+U8cW6lcVfPHGjnEWa3n+6t9l6Og5I4Ro=";
    };
    fabric-api = pkgs.fetchurl {
      url = "https://github.com/FabricMC/fabric/releases/download/0.57.0%2B1.19/fabric-api-0.57.0+1.19.jar";
      sha256 = "sha256-kqEYvI55QvK8+6NJZSoF0jqiWWwTMfUpB0SV8c5PZIM=";
    };
    geyser-fabric = pkgs.fetchurl {
      url = "https://ci.opencollab.dev/job/GeyserMC/job/Geyser-Fabric/job/java-1.18/196/artifact/build/libs/Geyser-Fabric.jar";
      sha256 = "sha256-YlRkxk7+mDasaKAQOWyfxDf3YXZOTDIkMzIAqy0Y9W0=";
    };
  };

  modpack = pkgs.runCommand "fabric-mods" {} ''
    mkdir $out
    ${concatStringsSep "\n" (lib.mapAttrsToList (name: mod: ''
      ln -sf ${mod} $out/${name}.jar
    '') mods)}
  '';

  # Ops
  ops = {
***REMOVED***
***REMOVED***
  };

  opsJson = let
    makeOp = name: uuid: {
      inherit name uuid;
      level = 3;
    };
  in pkgs.writeText "ops.json" (toJSON (lib.mapAttrsToList makeOp ops));
in {
  networking.firewall = {
    allowedTCPPorts = [ javaPort ];
    allowedUDPPorts = [ bedrockPort ];
  };

  services.minecraft-server = {
    inherit package;

    enable = true;
    eula = true;
    declarative = true;

    serverProperties = {
      motd = "UAV Minecraft";
      serverPort = javaPort;
      difficulty = "normal";
      gamemode = "survival";
      white-list = false; # access enforced by tailscale
      enable-rcon = true;
      max-players = 69420;
      spawn-protection = 0; # disable spawn protection
      "rcon.password" = "%RANDOM_PASSWORD%";
    };
  };

  systemd.services.minecraft-server = {
    # Don't automatically restart - very disruptive
    restartIfChanged = false;

    preStart = lib.mkAfter ''
      dataDir=${config.services.minecraft-server.dataDir}

      # Inject mods
      if [[ -d $dataDir/mods && ! -L $dataDir/mods ]]; then
        mv $dataDir/mods{,.old}
      fi
      ln -Tsf ${modpack} $dataDir/mods

      # Inject ops.json
      ln -sf ${opsJson} $dataDir/ops.json

      # Inject Geyser config
      mkdir -p $dataDir/config/Geyser-Fabric
      ln -sf ${./geyser.yml} $dataDir/config/Geyser-Fabric/config.yml

      # Inject random rcon password
      rcon_pass=$(${pkgs.openssl}/bin/openssl rand -hex 32)
      touch $dataDir/rcon.pass
      chmod 600 $dataDir/rcon.pass
      echo $rcon_pass >$dataDir/rcon.pass
      sed -i "s|%RANDOM_PASSWORD%|$rcon_pass|g" $dataDir/server.properties
    '';
  };

  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "mcrcon" ''
      set -euo pipefail
      export MCRCON_PASS=$(cat ${config.services.minecraft-server.dataDir}/rcon.pass)
      exec ${pkgs.mcrcon}/bin/mcrcon "$@"
    '')
  ];
}
