{
    gaming =
        {
            pkgs,
            ...
        }:
        {
            environment.systemPackages = [
                (pkgs.prismlauncher.override {
                    jdks = with pkgs; [
                        jdk21
                        jdk17
                        jdk8
                        jdk25
                    ];
                })
            ];

            preserveHome.directories = [ ".local/share/PrismLauncher" ];
        };
}
