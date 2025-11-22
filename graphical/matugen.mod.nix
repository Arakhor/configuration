{
  graphical.home =
    { pkgs, lib, ... }:
    let
      pywalfox-wrapper = pkgs.writeShellScriptBin "pywalfox-wrapper" ''
        ${pkgs.pywalfox-native}/bin/pywalfox start
      '';
    in
    {
      packages = [
        pkgs.matugen
        pkgs.pywalfox-native
      ];

      file.home.".mozilla/native-messaging-hosts/pywalfox.json".text =
        lib.replaceStrings [ "<path>" ] [ "${pywalfox-wrapper}/bin/pywalfox-wrapper" ]
          (
            builtins.readFile "${pkgs.pywalfox-native}/lib/python3.13/site-packages/pywalfox/assets/manifest.json"
          );

      file.xdg_config."matugen".source = "{{home}}/configuration/matugen";
    };
}
