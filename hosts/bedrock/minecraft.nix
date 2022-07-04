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
    fabric-api = pkgs.fetchurl {
      url = "https://github.com/FabricMC/fabric/releases/download/0.57.0%2B1.19/fabric-api-0.57.0+1.19.jar";
      sha256 = "sha256-kqEYvI55QvK8+6NJZSoF0jqiWWwTMfUpB0SV8c5PZIM=";
    };
    geyser-fabric = pkgs.fetchurl {
      url = "https://ci.opencollab.dev/job/GeyserMC/job/Geyser-Fabric/job/java-1.18/196/artifact/build/libs/Geyser-Fabric.jar";
      sha256 = "sha256-YlRkxk7+mDasaKAQOWyfxDf3YXZOTDIkMzIAqy0Y9W0=";
    };
  };

  # Ops
  ops = {
***REMOVED***
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
      "rcon.password" = builtins.readFile ./rcon.key;
    };
  };

  systemd.services.minecraft-server = {
    # Don't automatically restart - very disruptive
    restartIfChanged = false;

    preStart = lib.mkAfter ''
      dataDir=${config.services.minecraft-server.dataDir}

      # Inject mods
      mkdir -p $dataDir/mods
      ${concatStringsSep "\n" (lib.mapAttrsToList (name: mod: ''
        echo "Installing mod ${name}..."
        ln -sf ${mod} $dataDir/mods/${name}.jar
      '') mods)}

      # Inject ops.json
      ln -sf ${opsJson} $dataDir/ops.json

      # Inject Geyser config
      mkdir -p $dataDir/config/Geyser-Fabric
      ln -sf ${./geyser.yml} $dataDir/config/Geyser-Fabric/config.yml
    '';
  };

  deployment.keys."rcon.key" = {
    destDir = "/var/lib/secrets";
    keyFile = ./rcon.key;
  };

  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "mcrcon" ''
      export MCRCON_PASS=$(cat /var/lib/secrets/rcon.key)
      exec ${pkgs.mcrcon}/bin/mcrcon "$@"
    '')
  ];
}
