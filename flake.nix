{
  description = "arakhor's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # EXTENSIONS:
    nix-maid.url = "github:viperML/nix-maid";
    wrapper-manager.url = "github:viperML/wrapper-manager";
    preservation.url = "github:nix-community/preservation";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    xremap.url = "github:xremap/nix-flake";
    xremap.inputs.nixpkgs.follows = "nixpkgs";

    # HARDWARE:
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # PACKAGES:
    niri.url = "github:sodiboo/niri-flake";
    nushell-nightly.url = "github:JoaquinTrinanes/nushell-nightly-flake";
    ghostty.url = "github:ghostty-org/ghostty";
    helix.url = "github:helix-editor/helix";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";

    # DMS:
    dms.url = "github:AvengeMedia/DankMaterialShell";
    dms.inputs.nixpkgs.follows = "nixpkgs";
    dms-plugins.url = "github:AvengeMedia/dms-plugins";
    dms-plugins.flake = false;
    dgop.url = "github:AvengeMedia/dgop";
    dgop.inputs.nixpkgs.follows = "nixpkgs";
    danksearch.url = "github:AvengeMedia/danksearch";
    danksearch.inputs.nixpkgs.follows = "nixpkgs";

    quickshell.follows = "dms";

    matugen.url = "github:InioX/matugen";
    matugen.inputs.nixpkgs.follows = "nixpkgs";

    # MISC:
    treefmt-nix.url = "github:numtide/treefmt-nix";

    topiary-nushell.url = "github:blindFS/topiary-nushell";
    topiary-nushell.flake = false;

    nu-batteries.url = "github:nome/nu-batteries";
    nu-batteries.flake = false;

    monurepo.url = "github:YPares/monurepo";
  };

  outputs =
    raw-inputs:
    let
      inputs = builtins.mapAttrs (
        input-name: raw-input:
        builtins.foldl' (
          input: module-class:
          if input ? ${module-class} then
            input
            // {
              ${module-class} = builtins.mapAttrs (
                module-name:
                raw-inputs.nixpkgs.lib.setDefaultModuleLocation "${input-name}.${module-class}.${module-name}"
              ) input.${module-class};
            }
          else
            input
        ) raw-input [ "nixosModules" ]
      ) raw-inputs;
    in
    let
      inherit (inputs) self nixpkgs;

      inherit (nixpkgs.lib.attrsets) filterAttrs mapAttrs zipAttrs;
      inherit (nixpkgs.lib.strings) hasSuffix;
      inherit (nixpkgs.lib.lists) filter map;

      inherit (nixpkgs.lib.trivial) const toFunction;
      inherit (nixpkgs.lib.filesystem) listFilesRecursive;
      inherit (nixpkgs.lib.modules) setDefaultModuleLocation;

      params = inputs // {
        profiles = raw-configs;
        systems = mapAttrs (const (system: system.config)) configs;
      };

      # It is important to note, that when adding a new `.mod.nix` file, you need to run `git add` on the file.
      # If you don't, the file will not be included in the flake, and the modules defined within will not be loaded.
      all-modules =
        map (
          path:
          mapAttrs (profile: setDefaultModuleLocation "${path}#${profile}") (toFunction (import path) params)
        ) (filter (hasSuffix ".mod.nix") (listFilesRecursive "${self}"))
        ++ [
          { universal.options.id = nixpkgs.lib.mkOption { type = nixpkgs.lib.types.int; }; }

          elements
        ];

      elements = {
        # used as an identifier for ip addresses, etc.
        # and this set defines what systems are exported
        xps.id = 24;
        zeph.id = 96;
      };

      raw-configs = mapAttrs (const (
        modules:
        nixpkgs.lib.nixosSystem {
          inherit modules;
          specialArgs.lib = inputs.nixpkgs.lib.extend (final: prev: (import ./lib final));
        }
        // {
          inherit modules; # expose this next to e.g. `config`, `option`, etc.
        }
      )) (zipAttrs all-modules);

      configs = filterAttrs (name: config: elements ? ${name}) raw-configs;

      systems = [
        "x86_64-linux"
        "aarch64-linux" # i don't have such a machine, but might as well make the devtooling in this flake work out of the box.
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      treefmtEval = forAllSystems (
        system:
        inputs.treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} (import ./treefmt.nix inputs)
      );
    in
    {
      # devShells = forAllSystems (
      #     system:
      #     import ./shell.nix {
      #         inherit system;
      #         flake = self;
      #     }
      # );

      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      nixosConfigurations = configs;
    };
}
