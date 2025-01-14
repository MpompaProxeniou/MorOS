{ pkgs, lib, config, ... }:

lib.mkIf config.hardware.cpu.amd.enable {
  boot = lib.mkMerge [
    {
      kernelModules = [ "msr" "zenpower" ];
      extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    }

    # for older kernels, see https://github.com/NixOS/nixos-hardware/blob/c256df331235ce369fdd49c00989fdaa95942934/common/cpu/amd/pstate.nix
    (lib.mkIf
      (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.3") {
        kernelParams = [ "amd_pstate=active" ];
      })
  ];

  hardware.cpu.amd.updateMicrocode = true;

  # Ryzen cpu control
  systemd.services.zenstates =
    lib.mkIf config.hardware.cpu.amd.undervolt.enable {
      enable = true;
      description = "Ryzen Undervolt";
      after = [ "syslog.target" "systemd-modules-load.service" ];

      unitConfig = { ConditionPathExists = "${pkgs.zenstates}/bin/zenstates"; };

      serviceConfig = {
        User = "root";
        ExecStart =
          "${pkgs.zenstates}/bin/zenstates ${config.hardware.cpu.amd.undervolt.value}";
      };

      wantedBy = [ "multi-user.target" ];
    };
}
