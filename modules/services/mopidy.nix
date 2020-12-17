{ config, lib, pkgs, ... }:

with lib;

let

  name = "mopidy";

  cfg = config.services.mopidy;

  settingsType = with types;
    attrsOf (oneOf [ bool int str (listOf (oneOf [ int str ])) ]);

  mopidyToINI = generators.toINI {
    mkKeyValue = generators.mkKeyValueDefault {
      mkValueString = v:
        if isList v then
          concatStringsSep "," v
        else
          generators.mkValueStringDefault { } v;
    } " = ";
  };

in {

  ###### interface

  options = {

    services.mopidy = {

      settings = mkOption {
        type = types.attrsOf settingsType;
        default = { };
        description = ''
          Mopidy configuration, including extensions. Documented in more detail
          in the
          <link xlink:href="https://docs.mopidy.com/en/latest/config/">mopidy
          configuration documentation</link>.
        '';
        example = literalExample ''
          {
            core = {
              cache_dir = "$XDG_CACHE_DIR/mopidy";
              config_dir = "$XDG_CACHE_DIR/mopidy";
              data_dir = "$XDG_CACHE_DIR/mopidy";
              max_tracklist_length = 10000;
              restore_state = false;
            };
            logging = {
              verbosity = 0;
              format = "%(levelname)-8s %(asctime)s [%(process)d:%(threadName)s] %(name)s\n  %(message)s";
              color = true;
            };
            audio = {
              mixer = "software";
              mixer_volume = 50;
              output = "autoaudiosink";
            };
            local = {
              enabled = true;
              media_dir = "$HOME/music/";
              max_search_results = 100;
              scan_timeout = 200;
              scan_follow_symlinks = true;
              included_file_extensions = [".flac" ".mp3" ".ogg"];
              user_artist_sortname = true;
            };
          };
        '';
      };

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable Mopidy, the extensible music server.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.mopidy;
        defaultText = literalExample "pkgs.mopidy";
        description = "Package providing mopidy";
      };

      extensions = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExample ''
          [ pkgs.mopidy-local pkgs.mopidy-somafm pkgs.mopidy-mpd ]
        '';
        description = "List of extensions added to mopidy";
      };
    };

  };

  ###### implementation

  config = let
    mopidyExtended = pkgs.symlinkJoin {
      name = "mopidy-with-modules";
      paths = [ cfg.package ] ++ cfg.extensions;
    };

  in mkIf cfg.enable {

    xdg.configFile."mopidy/mopidy.conf".text = mopidyToINI cfg.settings;

    home.packages = [ mopidyExtended ];

    systemd.user.services.mopidy = {
      Unit = {
        After = [ "network.target" "sound.target" ];
        Description = "Music Player Daemon";
      };

      Install = { WantedBy = [ "default.target" ]; };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${mopidyExtended}/bin/mopidy";
        Type = "notify";
      };
    };
  };
}
