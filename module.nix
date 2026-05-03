{ config, lib, pkgs, inputs, ... }:

let cfg = config.services.smu;
in {
  options.services.smu.enable = lib.mkEnableOption "SMU";

  config = lib.mkIf cfg.enable {
    users.groups.smu-input = {};
    boot.kernelModules = [ "uinput" ];

    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="smu-input", TAG+="uaccess", OPTIONS+="static_node=uinput"
      SUBSYSTEM=="input", KERNEL=="event*", MODE="0660", GROUP="smu-input", TAG+="uaccess"
    '';

    environment.systemPackages = [
      inputs.smu.packages.x86_64-linux.default
    ];
  };
}
