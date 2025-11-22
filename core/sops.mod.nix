{ sops-nix, ... }:
{
  universal =
    { pkgs, config, ... }:
    {
      imports = [ sops-nix.nixosModules.sops ];

      preserveHome.files = [ ".config/sops/age/keys.txt" ];

      sops.age.sshKeyPaths =
        if config.preservation.enable then
          # secrets are decrypted *before* persistence kicks in
          [ "/persist/etc/ssh/ssh_host_ed25519_key" ]
        else
          [ "/etc/ssh/ssh_host_ed25519_key" ];
      sops.defaultSopsFormat = "yaml";
      environment.systemPackages = [ pkgs.sops ];

      # sops.defaultSopsFile = ../secrets.yaml;
    };

  xps.sops.defaultSopsFile = ./secrets/xps.yaml;
}
