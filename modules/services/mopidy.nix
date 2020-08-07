{ config, lib, pkgs, ... }:

with lib;

let

  name = "mopidy";

  cfg = config.services.mopidy;

in {

  ###### interface

  options = {

    services.mopidy = {

      # FIXME: Rewrite the whole thing to use the INI generator
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable Mopidy, the extensible music server.
        '';
      };

     musicDirectory = mkOption {
        type = types.path;
        default = "${config.home.homeDirectory}/music";
        defaultText = "$HOME/music";
        apply = toString;       # Prevent copies to Nix store.
        description = ''
          The directory where mopidy reads music from.
        '';
      };

      playlistDirectory = mkOption {
        type = types.path;
        default = "${cfg.dataDir}/playlists";
        defaultText = ''''${dataDir}/playlists'';
        apply = toString;       # Prevent copies to Nix store.
        description = ''
          The directory where mopidy stores playlists.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra directives added to to the end of mopidy's configuration
          file, <filename>mopidy.conf</filename>. Basic configuration
          like file location and uid/gid is added automatically to the
          beginning of the file. For available options see
          <citerefentry>
            <refentrytitle>mopidy.conf</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry>.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "${config.xdg.dataHome}/${name}";
        defaultText = "$XDG_DATA_HOME/mopidy";
        apply = toString;       # Prevent copies to Nix store.
        description = ''
          The directory where mopidy stores its state, tag cache,
          playlists etc.
        '';
      };

     network = {

        listenAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          example = "any";
          description = ''
            The address for the daemon to listen on.
            Use <literal>any</literal> to listen on all addresses.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 6600;
          description = ''
            The TCP port on which the the daemon will listen.
          '';
        };

      };

      dbFile = mkOption {
        type = types.nullOr types.str;
        default = "${cfg.dataDir}/tag_cache";
        defaultText = ''''${dataDir}/tag_cache'';
        description = ''
          The path to MPD's database. If set to
          <literal>null</literal> the parameter is omitted from the
          configuration.
        '';
      };
    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    systemd.user.services.mopidy = {
      Unit = {
        After = [ "network.target" "sound.target" ];
        Description = "Music Player Daemon";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${pkgs.mopidy}/bin/mopidy --no-daemon ${mopidyConf}";
        Type = "notify";
        ExecStartPre = ''${pkgs.bash}/bin/bash -c "${pkgs.coreutils}/bin/mkdir -p '${cfg.dataDir}' '${cfg.playlistDirectory}'"'';
      };
    };
  };

}
