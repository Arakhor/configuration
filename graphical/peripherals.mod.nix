{
  graphical = {
    programs.adb.enable = true;
    programs.droidcam.enable = true;
    users.users.arakhor.extraGroups = [ "adbusers" ];

    services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.devmon.enable = true;
  };

  xps = {
    services.upower.enable = true;
  };
}
