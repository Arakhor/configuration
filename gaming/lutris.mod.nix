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
        };
}
