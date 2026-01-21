{
    description = "arakhor's flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

        nix-maid.url = "github:viperML/nix-maid";
        wrapper-manager.url = "github:viperML/wrapper-manager";
        preservation.url = "github:nix-community/preservation";

        nix-index-database.url = "github:nix-community/nix-index-database";
        nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

        rust-overlay.url = "github:oxalica/rust-overlay";
        rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
        fenix.url = "github:nix-community/fenix";
        fenix.inputs.nixpkgs.follows = "nixpkgs";
        naersk.url = "github:nix-community/naersk";
        naersk.inputs.nixpkgs.follows = "nixpkgs";
        crane.url = "github:ipetkov/crane";

        xremap.url = "github:xremap/nix-flake";
        xremap.inputs.nixpkgs.follows = "nixpkgs";

        disko.url = "github:nix-community/disko/latest";
        disko.inputs.nixpkgs.follows = "nixpkgs";

        cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

        niri.url = "github:sodiboo/niri-flake/very-refactor";
        niri-fork.url = "github:Naxdy/niri";
        niri-fork.inputs.nixpkgs.follows = "nixpkgs";
        niri-scratchpad.url = "github:argosnothing/niri-scratchpad";
        niri-scratchpad.inputs.nixpkgs.follows = "nixpkgs";
        nirinit.url = "github:amaanq/nirinit";
        nirinit.inputs.nixpkgs.follows = "nixpkgs";

        nushell-nightly.url = "github:JoaquinTrinanes/nushell-nightly-flake";
        topiary-nushell.url = "github:blindFS/topiary-nushell";
        topiary-nushell.inputs.nixpkgs.follows = "nixpkgs";
        nu-lint.url = "git+https://codeberg.org/wvhulle/nu-lint";
        nu-lint.inputs.nixpkgs.follows = "nixpkgs";

        ghostty.url = "github:ghostty-org/ghostty";

        helix.url = "github:helix-editor/helix/master";
        yazi.url = "github:sxyazi/yazi";

        vicinae.url = "github:vicinaehq/vicinae";
        vicinae-extensions.url = "github:vicinaehq/extensions";
        vicinae-extensions.inputs.nixpkgs.follows = "vicinae/nixpkgs";
        vicinae-extensions.inputs.vicinae.follows = "vicinae";

        noctalia.url = "github:noctalia-dev/noctalia-shell";
        noctalia.inputs.nixpkgs.follows = "nixpkgs";
        noctalia-plugins.url = "github:noctalia-dev/noctalia-plugins";
        noctalia-plugins.flake = false;

        matugen.url = "github:InioX/matugen";
        matugen.inputs.nixpkgs.follows = "nixpkgs";

        helium.url = "github:linuxmobile/mynixpkgs";
        helium.inputs.nixpkgs.follows = "nixpkgs";

        zen-browser.url = "github:0xc000022070/zen-browser-flake";
        zen-browser.inputs.nixpkgs.follows = "nixpkgs";

        glide-browser.url = "github:glide-browser/glide.nix";
        glide-browser.inputs.nixpkgs.follows = "nixpkgs";

        wiremix.url = "github:tsowell/wiremix";
        wiremix.inputs.nixpkgs.follows = "nixpkgs";

        treefmt-nix.url = "github:numtide/treefmt-nix";

        wallpapers.url = "github:DenverCoder1/minimalistic-wallpaper-collection";
        wallpapers.flake = false;

        nix-gaming-edge.url = "github:powerofthe69/nix-gaming-edge";
        nix-gaming-edge.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs =
        raw-inputs:
        let
            inputs =
                raw-inputs
                |> builtins.mapAttrs (
                    input-name: raw-input:
                    if raw-input ? nixosModules then
                        raw-input
                        // {
                            nixosModules = builtins.mapAttrs (
                                module-name:
                                raw-inputs.nixpkgs.lib.setDefaultModuleLocation "${input-name}.nixosModules.${module-name}"
                            ) raw-input.nixosModules;
                        }
                    else
                        raw-input
                );
        in
        let
            inherit (inputs) self nixpkgs;
            inherit (builtins) filter mapAttrs foldl';

            inherit (nixpkgs.lib.attrsets) filterAttrs zipAttrs;
            inherit (nixpkgs.lib.strings) hasSuffix;

            inherit (nixpkgs.lib.trivial) const toFunction;
            inherit (nixpkgs.lib.filesystem) listFilesRecursive;
            inherit (nixpkgs.lib.modules) setDefaultModuleLocation;

            lib = nixpkgs.lib.extend (
                final: prev:
                "${self}"
                |> listFilesRecursive
                |> filter (hasSuffix ".lib.nix")
                |> map (
                    p: final: prev:
                    import p self final
                )
                |> foldl' (acc: ext: acc // (ext final prev)) { }
            );

            params = inputs // {
                profiles = raw-configs;
                sources = import ./npins;
                systems = mapAttrs (const (system: system.config)) configs;
            };

            elements = {
                # used as an identifier for ip addresses, etc.
                # and this set defines what systems are exported
                xps.id = 24;
                zeph.id = 96;
            };

            # It is important to note, that when adding a new `.mod.nix` file, you need to run `git add` on the file.
            # If you don't, the file will not be included in the flake, and the modules defined within will not be loaded.
            all-modules =
                (
                    "${self}"
                    |> listFilesRecursive
                    |> filter (hasSuffix ".mod.nix")
                    |> map (
                        file:
                        mapAttrs (profile: setDefaultModuleLocation "${file}#${profile}") (toFunction (import file) params)
                    )
                )
                ++ [
                    { universal.options.id = lib.mkOption { type = lib.types.int; }; }
                    elements
                ];

            raw-configs = mapAttrs (const (
                modules:
                lib.nixosSystem {
                    inherit modules;
                    # pkgs = import nixpkgs {
                    #     system = modules.config.nixpkgs.system;
                    #     overlays = [ autoOverlay ];
                    # };
                }
                // {
                    inherit modules; # expose this next to e.g. `config`, `option`, etc.
                }
            )) (zipAttrs all-modules);

            configs = filterAttrs (name: config: elements ? ${name}) raw-configs;

            systems = [ "x86_64-linux" ];

            forAllSystems = lib.genAttrs systems;

            treefmtEval = forAllSystems (
                system:
                inputs.treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} (import ./treefmt.nix inputs)
            );
        in
        {
            formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

            checks = forAllSystems (system: {
                formatting = treefmtEval.${system}.config.build.check self;
            });

            nixosConfigurations = configs;
        };
}
