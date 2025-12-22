inputs: {
  universal =
    { lib, nixosConfig, ... }:
    let
      configDir = "/home/arakhor/configuration";
    in
    {
      programs.nh.enable = true;
      programs.nh.flake = configDir;
      preserveHome.directories = [ "configuration" ];

      # Include flake git rev in system label
      system.nixos.label = lib.concatStringsSep "-" (
        (lib.sort (x: y: x < y) nixosConfig.system.nixos.tags)
        ++ [ "${nixosConfig.system.nixos.version}-${inputs.self.sourceInfo.shortRev or "dirty"}" ]
      );

      # Useful for finding the exact config that built a generation
      environment.etc = {
        current-flake.source = inputs.self;
        current-rev.text = "${inputs.self.sourceInfo.rev or "dirty"}";
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

      # List of programs that require the bind mount to compile:
      # - mongodb
      nix.settings.build-dir = lib.mkIf nixosConfig.preservation.enable "/var/nix-tmp";
      systemd.tmpfiles.rules = lib.mkIf nixosConfig.preservation.enable [
        "d /var/nix-tmp 0755 root root - -"
        "d /persist/var/nix-tmp 0755 root root - -"
      ];

      programs.nushell = {
        interactiveShellInit = # nu
          ''
            inspect-host [host] {
              nixos-rebuild repl --flake $"${configDir}#($host)"
            }
            build-package [path] {
              NIXPKGS_ALLOW_UNFREE=1 nix build --impure --expr $"with import <nixpkgs> {}; pkgs.callPackage ($path) {}"
            }
          '';
        shellAliases = {
          mount-nix-tmp = lib.mkIf nixosConfig.preservation.enable "sudo mount --bind /state/var/nix-tmp /var/nix-tmp";
          system-size = "nix path-info --closure-size --human-readable /run/current-system";
        };
      };

    };
}
