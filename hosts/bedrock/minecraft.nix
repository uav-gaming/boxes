{ lib, pkgs, config, ... }:

with builtins;

let
  # Java Edition
  javaPort = 25565;
  package = pkgs.fabricServers.fabric-1_19;

  # Bedrock/Pocket (GeyserMC)
  bedrockPort = 19132;
  geyser = pkgs.fetchurl {
    url = "https://ci.opencollab.dev/job/GeyserMC/job/Geyser/job/master/1140/artifact/bootstrap/standalone/target/Geyser.jar";
    sha256 = "sha256-CmGt8JCNFj8ofTsF87r3gQI8yezAeMipUAn5zz14buY=";
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

    # Manage ops.json with nix
    preStart = lib.mkAfter ''
      ln -sf ${opsJson} ${config.services.minecraft-server.dataDir}/ops.json
    '';
  };

  systemd.services.geyser = {
    wantedBy = [ "multi-user.target" ];
    requires = [ "minecraft-server.service" ];
    after = [ "minecraft-server.service" ];

    path = with pkgs; [ coreutils jre ];
    script = ''
      ln -sf ${./geyser.yml} /var/lib/geyser/config.yml
      exec java -Xms1024M -jar ${geyser}
    '';

    serviceConfig = {
      StateDirectory = "geyser";
      WorkingDirectory = "/var/lib/geyser";
      DynamicUser = "yes";

      ProtectSystem = "full";
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      LockPersonality = true;
    };
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
