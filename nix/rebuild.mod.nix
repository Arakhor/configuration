inputs: {
    universal =
        {
            lib,
            config,
            pkgs,
            ...
        }:
        let
            configDir = "/home/arakhor/configuration";
        in
        {
            programs.nh.enable = true;
            programs.nh.flake = configDir;

            # Include flake git rev in system label
            system.nixos.label = lib.concatStringsSep "-" (
                (lib.sort (x: y: x < y) config.system.nixos.tags)
                ++ [ "${config.system.nixos.version}-${inputs.self.sourceInfo.shortRev or "dirty"}" ]
            );

            # Prevent builds failing just because we can't contact a substituter
            nix.settings.fallback = true;

            # Useful for finding the exact config that built a generation
            environment.etc = {
                current-flake.source = inputs.self;
                current-rev.text = "${inputs.self.sourceInfo.rev or "dirty"}";
                nixpkgs.source = pkgs.path;
            };

            # Sometimes nixos-rebuild compiles large pieces software that require more
            # space in /tmp than my tmpfs can provide. The obvious solution is to mount
            # /tmp to some actual storage. However, the majority of my rebuilds do not
            # need the extra space and I'd like to avoid the extra disk wear. By using a
            # custom tmp directory for nix builds, I can bind mount the build dir to
            # persistent storage when I know the build will be large. This wouldn't be
            # possible with the standard /tmp dir because bind mounting /tmp on a running
            # system would break things.
            # Relevant github issue: https://github.com/NixOS/nixpkgs/issues/54707
            nix.settings.build-dir = lib.mkIf config.preservation.enable "/var/nix-tmp";
            systemd.tmpfiles.rules = lib.mkIf config.preservation.enable [
                "d /var/nix-tmp 0755 root root - -"
                "d /state/var/nix-tmp 0755 root root - -"
            ];

            nix.daemonIOSchedClass = "idle";
            nix.daemonCPUSchedPolicy = "idle";

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

                substituters = [ "https://nix-community.cachix.org" ];
                trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
            };

            programs.nushell = {
                initConfig = # nu
                    ''
                        def build-package [path] {
                          NIXPKGS_ALLOW_UNFREE=1 nix build --impure --expr $"with import <nixpkgs> {}; pkgs.callPackage ($path) {}"
                        }
                    '';
                shellAliases = {
                    cfg = "nh os";
                    mount-nix-tmp = lib.mkIf config.preservation.enable "sudo mount --bind /state/var/nix-tmp /var/nix-tmp";
                    system-size = "nix path-info --closure-size --human-readable /run/current-system";
                };
            };

            preserveHome.directories = [
                "configuration"
                ".cache/nix"
                ".config/nix"
            ];
        };
}
