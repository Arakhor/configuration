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
          (final: prev: {
            wrapped = config.system.build.wrapper-manager.packages;
            mkWrapper =
              module:
              let
                finalModule =
                  if builtins.isAttrs module then
                    (
                      {
                        # show the actual file that defines the wrapper in case of error
                        _file = (builtins.unsafeGetAttrPos "basePackage" module).file;
                      }
                      // module
                    )
                  else
                    module;
              in
              wrapper-manager.lib.wrapWith final finalModule;
          })
        ];
      };
    };
}
