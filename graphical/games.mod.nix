{
  graphical =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.steam-run ];

      programs.steam = {
        enable = true;
        protontricks.enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };

      preserveHome.directories = [
        ".steam"
        ".local/share/Steam"
      ];
    };
}
