{ wrapper-manager, ... }:
{
  universal.nixpkgs.overlays = [
    (final: _prev: {
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

}
