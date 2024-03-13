{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixie.services.trino;

  node_config = ''
    node.environment=production
    node.id=ffffffff-ffff-ffff-ffff-ffffffffffff
    node.data-dir=/var/lib/trino/data
  '';

  jvm_config = ''
    -server
    -Xmx16G
    -XX:InitialRAMPercentage=80
    -XX:MaxRAMPercentage=80
    -XX:G1HeapRegionSize=32M
    -XX:+ExplicitGCInvokesConcurrent
    -XX:+ExitOnOutOfMemoryError
    -XX:+HeapDumpOnOutOfMemoryError
    -XX:-OmitStackTraceInFastThrow
    -XX:ReservedCodeCacheSize=512M
    -XX:PerMethodRecompilationCutoff=10000
    -XX:PerBytecodeRecompilationCutoff=10000
    -Djdk.attach.allowAttachSelf=true
    -Djdk.nio.maxCachedBufferSize=2000000
    -Dfile.encoding=UTF-8
    # Reduce starvation of threads by GClocker, recommend to set about the number of cpu cores (JDK-8192647)
    -XX:+UnlockDiagnosticVMOptions
    -XX:GCLockerRetryAllocationCount=32
    # Allow loading dynamic agent used by JOL
    -XX:+EnableDynamicAgentLoading
  '';

  coordinator_config_properties = ''
    coordinator=true
    node-scheduler.include-coordinator=false
    http-server.http.port=${toString cfg.port}
    discovery.uri=http://${cfg.hostName}:${toString cfg.port}
  '';

  worker_config_properties = ''
    coordinator=false
    http-server.http.port=${toString cfg.port}
    discovery.uri=http://${cfg.hostName}:${toString cfg.port}
  '';

  combined_config_properties = ''
    coordinator=true
    node-scheduler.include-coordinator=true
    http-server.http.port=${toString cfg.port}
    discovery.uri=http://${cfg.hostName}:${toString cfg.port}
  '';

  config_properties =
    if cfg.role == "coordinator"
    then coordinator_config_properties
    else if cfg.role == "worker"
    then worker_config_properties
    else combined_config_properties;

  inherit (lib) mkEnableOption mkIf mkOption types;
in {
  options.nixie.services.trino = {
    enable = mkEnableOption "trino";

    port = mkOption {
      type = types.int;
      default = 8080;
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Whether to open the TCP port in the firewall";
    };

    hostName = mkOption {
      type = types.str;
      default = "localhost";
    };

    role = mkOption {
      type = types.enum ["coordinator" "worker" "combined"];
      default = "combined";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.port];

    environment.systemPackages = [
      pkgs.trino
    ];

    users.users.trino = {
      isSystemUser = true;
      group = "trino";
      description = "Trino server daemon user";
    };
    users.groups.trino = {};

    systemd = {
      services.trino = {
        after = ["network.target"];
        path = with pkgs; [bash python3];
        serviceConfig = {
          ExecStart = "${pkgs.trino}/bin/launcher start";
          ExecStop = "${pkgs.trino}/bin/launcher stop";
          Type = "forking";
          User = "trino";

          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          StateDirectory = "trino";
        };
      };

      tmpfiles.rules = [
        "d /var/lib/trino 0700 trino trino -"
      ];
    };

    system.activationScripts.trino = ''
      echo "${node_config}" > /var/lib/trino/node.properties
      echo "${jvm_config}" > /var/lib/trino/jvm.config
      echo "${config_properties}" > /var/lib/trino/config.properties
    '';
  };
}
