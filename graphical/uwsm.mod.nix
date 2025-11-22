{
  graphical =
    {
      pkgs,
      lib,
      nixosConfig,
      ...
    }:
    {
      programs.uwsm = {
        enable = true;
        waylandCompositors.niri = {
          prettyName = "niri";
          comment = "niri compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/niri-session";
        };
      };

      environment = {
        systemPackages = [ pkgs.app2unit ];
        sessionVariables.APP2UNIT_SLICES = "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice";
        # Even though I use the -t service flag pretty much everywhere in my
        # config still keep the default behaviour as scope because this is
        # generally how apps should be launched if we interactively run `app2unit
        # app.desktop` in a terminal. Launching with a keybind, launcher or
        # script should run the the app in a service since there's no value in
        # process or input/output inheritance in these cases.
        sessionVariables.APP2UNIT_TYPE = "scope";
      };

      systemd.user.services.fumon = {
        enable = true;
        wantedBy = [ "graphical-session.target" ];
        path = lib.mkForce [ ]; # reason explained in desktop/default.nix
        serviceConfig.ExecStart = [
          "" # to replace original ExecStart
          (lib.getExe' nixosConfig.programs.uwsm.package "fumon")
        ];
      };
    };
}
