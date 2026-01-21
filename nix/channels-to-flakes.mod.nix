inputs: {
    universal =
        { lib, ... }:
        let
            flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
        in
        {
            nix = {
                channel.enable = false;

                # Populates the nix registry with all our flake inputs `nix registry list`
                # Enables referencing flakes with short name in nix commands
                # e.g. 'nix shell n#dnsutils' or 'nix shell hyprland#wlroots-hyprland'
                registry = (lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs) // {
                    self.flake = inputs.self;
                    n.flake = inputs.nixpkgs;
                };

                # Add flake inputs to nix path. Enables loading flakes with <flake_name>
                # like how <nixpkgs> can be referenced.
                nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

                # Do not load the default global registry
                # https://channels.nixos.org/flake-registry.json
                settings.flake-registry = "";
            };
        };
}
