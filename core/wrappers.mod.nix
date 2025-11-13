{ wrapper-manager, ... }:
{
  universal =
    {
      pkgs,
      lib,
      nixosConfig,
      ...
    }:
    {
      options.wrappers = lib.mkOption {
        description = '''';

        type = lib.types.attrsOf lib.types.attrs;
        default = { };
      };

      config.nixpkgs.overlays = [
        (
          final: prev:
          let
            evald = wrapper-manager.lib {
              pkgs = final;
              modules = [ { inherit (nixosConfig) wrappers; } ];
            };
          in
          {
            wrapped = lib.mapAttrs (_: value: value.wrapped) evald.config.wrappers;
          }
        )
      ];
    };
}
