{
    universal =
        { pkgs, ... }:
        let
            lixVersion = "stable";
        in
        {
            programs.direnv.nix-direnv.package = pkgs.lixPackageSets.${lixVersion}.nix-direnv;

            nixpkgs.overlays = [
                (final: prev: {
                    nixStable = prev.nix;
                    nix = final.lixPackageSets.${lixVersion}.lix;

                    inherit (final.lixPackageSets.${lixVersion})
                        nixpkgs-review
                        nix-eval-jobs
                        nix-fast-build
                        colmena
                        ;
                })
            ];
        };
}
