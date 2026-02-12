{ wrapper-manager, ... }:
{
    universal =
        {
            pkgs,
            config,
            ...
        }:
        let
            inherit (builtins) mapAttrs attrValues;
            wm = wrapper-manager.lib.eval { inherit pkgs; };
        in
        {
            options.wrappers = wm.options.wrappers;
            config = {
                wrappers = { };
                environment.systemPackages = attrValues (mapAttrs (_: value: value.wrapped) config.wrappers);
                nixpkgs.overlays = [
                    (final: prev: {
                        wrapped = mapAttrs (_: value: value.wrapped) config.wrappers;
                    })
                ];
            };
        };
}
