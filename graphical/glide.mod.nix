{ glide, ... }:
{
  graphical =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ glide.overlays.default ];
      home.packages = [ pkgs.glide-browser ];
      home.file.xdg_config."glide/glide.ts".text = # ts
        ''
          glide.g.mapleader = "<Space>";

          glide.prefs.set("devtools.debugger.prompt-connection", false);
          glide.prefs.set("media.videocontrols.picture-in-picture.audio-toggle.enabled", true);
          glide.prefs.set("browser.uidensity", 1); // compact mode

          glide.addons.install("https://addons.mozilla.org/firefox/downloads/file/4629131/ublock_origin-1.68.0.xpi")
        '';
    };

}
