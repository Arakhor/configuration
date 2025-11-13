{ niri, ... }:
{
  universal =
    { lib, nixosConfig, ... }:
    {
      lib = {
        nushell = import ./nushell.lib.nix { inherit lib; };
        types = import ./types.lib.nix { inherit lib; };
        gtk = import ./gtk.lib.nix { inherit lib; };
        kdl = niri.lib.kdl;
      };

      home = {
        options = {
          lib = lib.mkOption {
            type = lib.types.attrsOf lib.types.attrs;
            default = { };
            description = ''
              This option allows modules to define helper functions,
              constants, etc.
            '';
          };
        };
        config.lib = nixosConfig.lib;
      };
    };
}
