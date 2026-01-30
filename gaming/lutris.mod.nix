{
    gaming =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        {
            environment.systemPackages = [
                pkgs.lutris
            ];
            preserveHome.directories = [
                "games"
                ".local/share/lutris"
            ];
        };
}
