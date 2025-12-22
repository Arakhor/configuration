{ wrapper-manager, ... }:
{
  universal =
    { pkgs, config, ... }:
    let
      wm = (wrapper-manager.lib.eval { inherit pkgs; });
    in
    {

      options = {
        inherit (wm.options) wrappers;
      };

      config = {
        system.build.wrapper-manager = {
          toplevel = pkgs.buildEnv {
            name = "wrapper-manager-bundle";
            paths = builtins.attrValues config.system.build.wrapper-manager.packages;
          };

          packages = builtins.mapAttrs (_: value: value.wrapped) config.wrappers;
        };

        nixpkgs.overlays = [
          (_: _: {
            wrapped = config.system.build.wrapper-manager.packages;
          })
        ];
      };
    };
}
