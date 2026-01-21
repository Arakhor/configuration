{
    graphical =
        { pkgs, lib, ... }:
        {
            environment.systemPackages = [ pkgs.beeper ];

            preserveHome.directories = [ ".config/BeeperTexts" ];
        };
}
