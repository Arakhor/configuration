{
    graphical =
        { pkgs, ... }:
        {
            home.packages = [ pkgs.firefox ];
            preserveHome.directories = [ ".mozilla/firefox" ];
        };
}
