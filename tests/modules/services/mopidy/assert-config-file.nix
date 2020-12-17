{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    services.mopidy = {
      enable = true;
      foo = true;
      settings = {
        core = {
          cache_dir = "$XDG_CACHE_DIR/mopidy";
          config_dir = "$XDG_CACHE_DIR/mopidy";
          data_dir = "$XDG_CACHE_DIR/mopidy";
          max_tracklist_length = 10000;
          restore_state = false;
        };
        logging = {
          verbosity = 0;
          format = "%(levelname)-8s %(asctime)s [%(process)d:%(threadName)s]"
            + " %(name)s %(message)s";
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
          included_file_extensions = [ ".flac" ".mp3" ".ogg" ];
          user_artist_sortname = true;
        };
      };
    };

    home.stateVersion = "20.09";

    nixpkgs.overlays =
      [ (self: super: { mopidy = pkgs.writeScriptBin "dummy-mopidy" ""; }) ];

    nmt.script = ''
      assertFileExists home-files/.config/mopidy/mopidy.conf
      assertFileContent \
        home-files/.config/mopidy/mopidy.conf \
        ${./config-expected.conf}
    '';
  };
}
