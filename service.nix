{ lib, config, pkgs, ... }: let
  cfg = config.services.terrad;
  addrs = cfg.addresses;
  terrad = import ./default.nix {};

  addrbook = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/terra-money/testnet/master/bombay-12/addrbook.json";
    sha256 = "0p2bzlfrhrj86lpchhiaffmkn2658rvxb44pb24b664ci1zx4rrv";
  };

  genesis = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/terra-money/testnet/master/bombay-12/genesis.json";
    sha256 = "1mmxzw62gsgc6w10j7irrhrfwmyr8rgj7vv63vpdxfipdzv2v302";
  };
in {
  options.services.terrad = {
    enable = lib.mkEnableOption "terrad service";

    user = lib.mkOption {
      type = lib.types.str;
      default = "terrad";
      description = "User account under which terrad runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "terrad";
      description = "Group under which terrad runs.";
    };

    addresses = {
      address = lib.mkOption {
        description = "Listen address";
        default = "tcp://0.0.0.0:26658";
        type = lib.types.str;
      };
      grpcWebAddress = lib.mkOption {
        description = "The gRPC-Web server address to listen on";
        default = "0.0.0.0:9091";
        type = lib.types.str;
      };
      grpcAddress = lib.mkOption {
        description = "the gRPC server address to listen on";
        default = "0.0.0.0:9090";
        type = lib.types.str;
      };
      p2pAddress = lib.mkOption {
        description = "node listen address";
        default = "tcp://0.0.0.0:26656";
        type = lib.types.str;
      };
      rpcAddress = lib.mkOption {
        description = "RPC listen address. Port required";
        default = "tcp://127.0.0.1:26657";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.terrad = {
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      preStart = ''
        mkdir -p "$STATE_DIRECTORY/config"
        if [ ! -e "$STATE_DIRECTORY/config/addrbook.json" ]; then
          install -m 644 ${addrbook} "$STATE_DIRECTORY/config/addrbook.json"
        fi
        if [ ! -e "$STATE_DIRECTORY/config/genesis.json" ]; then
          install -m 644 ${genesis} "$STATE_DIRECTORY/config/genesis.json"
        fi
      '';
      serviceConfig = {
        ExecStart = "${terrad}/bin/terrad start --home \${STATE_DIRECTORY} --address ${addrs.address} --grpc-web.address ${addrs.grpcWebAddress} --grpc.address ${addrs.grpcAddress} --p2p.laddr ${addrs.p2pAddress} --rpc.laddr ${addrs.rpcAddress}";
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "terrad";
      };
    };

    users.users = lib.mkIf (cfg.user == "terrad") {
      terrad = {
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = lib.mkIf (cfg.group == "terrad") {
      terrad = {};
    };
  };
}
