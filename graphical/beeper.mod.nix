{
  graphical =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.beeper ];

      preserveHome.directories = [ ".config/BeeperTexts" ];
    };
}
