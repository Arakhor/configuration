{ nix-maid, ... }:
{
  universal =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        nix-maid.nixosModules.default

        (lib.mkAliasOptionModule [ "home" ] [ "users" "users" "arakhor" "maid" ])

        {
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
          };
        }
      ];

      users.mutableUsers = false;

      users.users.arakhor = {
        isNormalUser = true;
        description = "arakhor";
        extraGroups = [ "wheel" ];
        hashedPassword = "$y$j9T$2RCRnlUsztuzTPbLjkPN50$LCDo/lkk9QQUVfNl0Xm7yM85t/uwAato.JlP3pCsLj4";
      };

      _module.args.nixosConfig = config;
      _module.args.homeConfig = config.home;
      home._module.args.nixosConfig = config;

      systemd.tmpfiles.rules =
        let
          home = "/home/arakhor";
          name = "arakhor";
        in
        [
          "d ${home} 0700 ${name} ${config.users.users.${name}.group} - -"
          "z ${home} 0700 ${name} ${config.users.users.${name}.group} - -"
        ]
        ++ (lib.flatten (
          map
            (d: [
              "d ${home}/${d} 0755 ${name} users - -"
              "z ${home}/${d} 0755 ${name} users - -"
            ])
            [
              ".config"
              ".local"
              ".local/share"
              ".cache"
              ".ssh"

              # "Desktop"
              # "Documents"
              # "Downloads"
              # "Music"
              # "Pictures"
              # "Videos"
            ]
        ));
    };
}
