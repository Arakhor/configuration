{ determinate, ... }:
{
    universal =
        # { pkgs, homeConfig, ... }:
        {
            imports = [ determinate.nixosModules.default ];
            nix = {
                # package = pkgs.lixPackageSets.${lixVersion}.lix;

                settings = {
                    use-xdg-base-directories = true;
                    warn-dirty = false;
                    eval-cores = 0;
                    use-cgroups = true;
                    # Causes excessive writes and potential slow downs when writing
                    # content to the nix store. Optimising once a week with
                    # `nix.optimise.automatic` is probably better?
                    auto-optimise-store = false;
                    # Do not create a bunch of nixbld users
                    auto-allocate-uids = true;
                    allowed-users = [ "arakhor" ];
                    # trace-import-from-derivation = true;

                    experimental-features = [
                        "nix-command"
                        "flakes"
                        "pipe-operator"
                        "auto-allocate-uids"
                        "cgroups"
                    ];
                };
            };
            # nixpkgs.overlays = [
            #     (final: prev: {
            #         inherit (prev.lixPackageSets.${lixVersion})
            #             nixpkgs-review
            #             nix-eval-jobs
            #             nix-fast-build
            #             colmena
            #             ;
            #     })
            # ];
            preserveHome.directories = [ ".cache/nix" ];
        };
}
