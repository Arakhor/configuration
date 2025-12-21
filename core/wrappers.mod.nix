{ wrapper-manager, ... }:
{
  universal =
    { pkgs, config, ... }:
    let
      wm = (wrapper-manager.lib.eval { inherit pkgs; });
    in
    {

      options.wrapperManager = wm.options;
      config = {
        wrapperManager = {
          build = {
            toplevel = pkgs.buildEnv {
              name = "wrapper-manager-bundle";
              paths = builtins.attrValues config.wrapper-manager.build.packages;
            };

            packages = builtins.mapAttrs (_: value: value.wrapped) config.wrapperManager.wrappers;
          };
        };

        nixpkgs.overlays = [
          (final: prev: {
            wrapped = config.wrapperManager.build.packages;
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
