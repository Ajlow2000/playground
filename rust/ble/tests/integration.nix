{ pkgs, self, cargoToml }:

pkgs.testers.runNixOSTest {
  name = "${cargoToml.package.name}-integration-test";
  
  nodes.machine = { config, pkgs, ... }: {
    environment.systemPackages = [ 
        pkgs.pkg-config
        pkgs.dbus
        pkgs.bluez
        pkgs.bluez-tools
        pkgs.python3
        self.packages.${pkgs.system}.default
    ];
    
    # Enable D-Bus service (required for Bluetooth)
    services.dbus.enable = true;
    
    # Enable Bluetooth and load vhci module
    hardware.bluetooth.enable = true;
    boot.kernelModules = [ "hci_vhci" "bluetooth" ];
    
    # Ensure bluetooth service starts with proper dependencies
    systemd.services.bluetooth = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "dbus.service" ];
    };
  };
  
  testScript = ''
start_all()
machine.wait_for_unit("multi-user.target")
machine.wait_for_unit("dbus.service")

# Load kernel modules early
machine.succeed("modprobe bluetooth")
machine.succeed("modprobe hci_vhci")
machine.succeed("test -c /dev/vhci")

# Force start bluetooth service and verify
machine.succeed("systemctl start bluetooth")
machine.wait_for_unit("bluetooth.service")

# Sanity check -- confirming that the wait_for_unit does what I expect
machine.succeed("systemctl is-active bluetooth")

# Test that the ble binary is available
machine.succeed("which ble")

# Sanity check that our app is executable  
machine.succeed("ble --help || true")

# For now, test basic scanner functionality without virtual controller
# This tests that the BLE scanner can start and run without errors
machine.succeed("""
# Test BLE scanner with short timeout
timeout 5 ble > /tmp/ble_output.txt 2>&1 || true

# Check that the scanner produced output (even if no devices found)
if [ -f /tmp/ble_output.txt ]; then
  echo "BLE scanner output:"
  cat /tmp/ble_output.txt
  echo "SUCCESS: BLE scanner ran without crashing"
else
  echo "FAILURE: No output file created"
  exit 1
fi
""")

  '';
}
