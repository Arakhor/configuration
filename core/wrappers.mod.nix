{ wrapper-manager, ... }:
{
  universal =
    { pkgs, config, ... }:
    let
      wm = (wrapper-manager.lib.eval { inherit pkgs; });
    in
    {

      options.wrapper-manager = wm.options;
      config = {

        wrapper-manager = {
          build = {
            toplevel = pkgs.buildEnv {
              name = "wrapper-manager-bundle";
              paths = builtins.attrValues config.wrapper-manager.build.packages;
            };

            packages = builtins.mapAttrs (_: value: value.wrapped) config.wrapper-manager.wrappers;
          };
        };

        nixpkgs.overlays = [
          (final: prev: {
            wrapped = config.wrapper-manager.build.packages;
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
