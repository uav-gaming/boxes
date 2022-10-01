{ lib, pkgs, config, ... }:

with builtins;

let
  # Java Edition
  javaPort = 25565;
  package = pkgs.fabricServers.fabric-1_19_2;

  # Bedrock/Pocket (GeyserMC)
  bedrockPort = 19132;

  # Dynmap
  dynmapPort = 8123;

  # Fabric mods
  mods = {
    # Client-side mods
    # Item storage and transportation
    ae2 = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/XxWD5pD3/versions/Z8OKgUoh/appliedenergistics2-12.7.0.jar";
      sha256 = "sha256-vD0SmJGLlMr+nBo/1/gCMU4Uw/fvu8doVYq0vkxZnZQ=";
    };
    # Programmable robots
    cc-restitched = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/eldBwa5V/versions/1.101.2+1.19.1/cc-restitched-1.101.2.jar";
      sha256 = "sha256-fzts+Efvux1tlBRB/ntuZViXUuLLKYx1kAlvUwPITa8=";
    };
    # Recipes
    rei = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/nfn13YXA/versions/C8N1KDOt/RoughlyEnoughItems-9.1.546.jar";
      sha256 = "sha256-kqwWVz4cSwgubr/MK5zha4wJpgkgKmoKViY/FUdcXsY=";
    };

    # Server-only mods
    dynmap = pkgs.fetchurl {
      url = "https://dynmap.us/releases/Dynmap-3.4-fabric-1.19.1.jar";
      sha256 = "sha256-N4y0cevuQvN6tCuS/3pyMwn2HqGnj+dK5f4lorK69JI=";
    };

    # APIs
    # Depended by all mods.
    fabric-api = pkgs.fetchurl {
      url = "https://github.com/FabricMC/fabric/releases/download/0.62.0%2B1.19.2/fabric-api-0.62.0+1.19.2.jar";
      sha256 = "sha256-RXp1zYxFJ2tYF7dsGVEH3s0jnmQVEP7IjlOtkJGOolc=";
    };
    # Depended by REI.
    cloth-config = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/9s6osm5g/versions/EXrxCjl6/cloth-config-8.2.88-fabric.jar";
      sha256 = "sha256-Za+XancnMxaczbY0EFgAMFhAMv0pevFr7taoxkPq0AM=";
    };
    # Depended by REI.
    architectury = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/lhGA9TYQ/versions/xjWpId6m/architectury-6.2.46-fabric.jar";
      sha256 = "sha256-aUijRNgRmZdNTDJBoZKaxE2FqEnTcSr/jTqx1RU6oAI=";
    };
  };

  modpack = pkgs.runCommand "fabric-mods" {} ''
    mkdir $out
    ${concatStringsSep "\n" (lib.mapAttrsToList (name: mod: ''
      ln -sf ${mod} $out/${name}.jar
    '') mods)}
  '';

  opsKeyPath = ./minecraft-ops.key.nix;

  # Ops
  # Attr set[playname = uuid];
  ops = if config.uav-gaming.devEnv then import opsKeyPath
        else {};

  opsJson = let
    makeOp = name: uuid: {
      inherit name uuid;
      level = 3;
    };
  in pkgs.writeText "ops.json" (toJSON (lib.mapAttrsToList makeOp ops));
in {
  networking.firewall = {
    allowedTCPPorts = [ javaPort dynmapPort ];
    allowedUDPPorts = [ bedrockPort ];
  };

  services.minecraft-server = {
    inherit package;

    enable = true;
    eula = true;
    declarative = true;

    jvmOpts = "-Xms1G -Xmx8G";

    serverProperties = {
      difficulty = "normal";
      enable-rcon = true;
      gamemode = "survival";
      max-players = 69420;
      motd = "UAV Minecraft";
      pvp = false;
      "rcon.password" = "%RANDOM_PASSWORD%";
      serverPort = javaPort;
      spawn-protection = 0; # disable spawn protection
      tick-distance = 12; # [4, 12]. Lower this to avoid lag.
      white-list = false; # access enforced by tailscale
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

      # Inject Dynmap config
      mkdir -p $dataDir/dynmap
      ln -sf ${./dynmap-configuration.yml} $dataDir/dynmap/configuration.txt
      ln -sf ${./dynmap-permissions.yml} $dataDir/dynmap/permissions.yml

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
