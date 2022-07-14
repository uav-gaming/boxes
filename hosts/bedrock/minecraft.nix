{ lib, pkgs, config, ... }:

with builtins;

let
  # Java Edition
  javaPort = 25565;
  package = pkgs.fabricServers.fabric-1_19;

  # Bedrock/Pocket (GeyserMC)
  bedrockPort = 19132;

  # Dynmap
  dynmapPort = 8123;

  # Fabric mods
  mods = {
    # Client-side mods
    # Item storage and transportation
    ae2 = pkgs.fetchurl {
      url = "https://github.com/AppliedEnergistics/Applied-Energistics-2/releases/download/fabric%2Fv12.0.1-alpha/appliedenergistics2-12.0.1-alpha.jar";
      sha256 = "sha256-jaQ3S2Ya2ek++dGvwu/mDURzGnHfOt31UOFrKW9q2GQ=";
    };
    # Programmable robots
    cc-restitched = pkgs.fetchurl {
      url = "https://github.com/cc-tweaked/cc-restitched/releases/download/v1.19-1.101.0-ccr/cc-restitched-1.101.0.jar";
      sha256 = "sha256-7g5xfUjwOz+U8cW6lcVfPHGjnEWa3n+6t9l6Og5I4Ro=";
    };
    # In-game map
    journeymap = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/lfHFW1mp/versions/1.19-5.8.5rc2-fabric/journeymap-1.19-5.8.5rc2-fabric.jar";
      sha256 = "sha256-Fwed1BDIiB9O4L4iCyhDrXThGQyLbf7THakEiYasgHo=";
    };
    # Recipes
    rei = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/nfn13YXA/versions/9.1.511+fabric/RoughlyEnoughItems-9.1.511.jar";
      sha256 = "sha256-fKu0D5xdCCzYsqU61QZ5BPqw5ctID47eMOOXr1Y2mXg=";
    };

    # Server-only mods
    dynmap = pkgs.fetchurl {
      url = "https://dynmap.us/releases/Dynmap-3.4-beta-4-fabric-1.19.jar";
      sha256 = "sha256-gy0t2wQp5LEKGV8aoIwo7dzOYQwj5suko0UPGmF5VrY=";
    };

    # APIs
    # Depended by all mods.
    fabric-api = pkgs.fetchurl {
      url = "https://github.com/FabricMC/fabric/releases/download/0.57.0%2B1.19/fabric-api-0.57.0+1.19.jar";
      sha256 = "sha256-kqEYvI55QvK8+6NJZSoF0jqiWWwTMfUpB0SV8c5PZIM=";
    };
    # Depended by REI.
    cloth-config = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/9s6osm5g/versions/7.0.73+fabric/cloth-config-7.0.73-fabric.jar";
      sha256 = "sha256-zUPlyMYWXOb01mRIpCGoUvvR0g2M1WzghtamMVwlZJs=";
    };
    # Depended by REI.
    architectury = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/lhGA9TYQ/versions/5.9.30+fabric/architectury-5.9.30-fabric.jar";
      sha256 = "sha256-Zvol6IH+pmdR3l19piONCmGF7jrbnaMxNhpKi+g4S1Y=";
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
  ops = if config.uav-gaming.hasSecrets then import opsKeyPath
        else builtins.trace "${opsKeyPath} is not decrypted. Using default." {};

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
