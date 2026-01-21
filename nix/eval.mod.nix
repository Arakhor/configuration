{
    universal = {
        nix.settings = {
            use-xdg-base-directories = true;
            warn-dirty = false;
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
                "auto-allocate-uids"
                "cgroups"
                "pipe-operator"
            ];
        };

        maid-users.file.xdg_config."nixpkgs/config.nix".text = ''
            { allowUnfree = true; }
        '';

        preserveHome.directories = [
            ".cache/nix"
            ".config/nix"
        ];
    };
}
