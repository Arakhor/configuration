{
  universal =
    { pkgs, nixosConfig, ... }:
    let
      lixVersion = "latest";
    in
    {
      nix.package = pkgs.lixPackageSets.${lixVersion}.lix;
      programs.direnv.nix-direnv.package = pkgs.lixPackageSets.${lixVersion}.nix-direnv;

      nixpkgs.overlays = [
        (final: prev: {
          inherit (prev.lixPackageSets.${lixVersion})
            nixpkgs-review
            nix-eval-jobs
            nix-fast-build
            colmena
            ;
        })
      ];

      home.packages = [ nixosConfig.nix.package ];
    };
}
