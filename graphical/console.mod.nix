{
    graphical =
        { pkgs, nixosConfig, ... }:
        {
            services.kmscon = {
                enable = true;
                extraOptions = "--term xterm-256color";
                extraConfig = ''
                    font-size=24
                    xkb-layout=${nixosConfig.locale.keyboard-layout}
                '';
                hwRender = true;
                fonts = [
                    {
                        name = "Lilex Nerd Font";
                        package = pkgs.nerd-fonts.lilex;
                    }
                ];
            };
        };
}
