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
      sops.secrets."users/arakhor/password".neededForUsers = true;

      users.users.arakhor = {
        isNormalUser = true;
        description = "arakhor";
        extraGroups = [
          "wheel"
          "greeter"
        ];
        hashedPasswordFile = config.sops.secrets."users/arakhor/password".path;
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
