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
      ];

      users.mutableUsers = false;
      # sops.secrets."user/arakhor/password".neededForUsers = true;

      users.users.arakhor = {
        isNormalUser = true;
        description = "arakhor";
        extraGroups = [
          "wheel"
          "greeter"
        ];
        # hashedPasswordFile = config.sops.secrets."user/arakhor/password".path;
        hashedPassword = "$y$j9T$zx4TCrMTNKM4drj3Tqae2.$ntS.6gvtScUra.N8VK2ovxv4FHnz.Xlj4ucTr43.Sz/";
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
