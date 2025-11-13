{
  graphical.home =
    { pkgs, ... }:
    {
      packages = [ pkgs.pywalfox-native ];
      file.xdg_config."matugen".source = "{{home}}/configuration/matugen";
    };
}
