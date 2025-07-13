{ pkgs, self, cargoToml }:

pkgs.testers.runNixOSTest {
  name = "${cargoToml.package.name}-integration-test";
  
  nodes.machine = { config, pkgs, ... }: {
    environment.systemPackages = [ 
        pkgs.pkg-config
        pkgs.dbus
        self.packages.${pkgs.system}.default
    ];
  };
  
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    
    # Test that the ble binary is available
    machine.succeed("which ble")
    
    # Test that the ble binary runs and produces expected output
    # output = machine.succeed("ble").strip()
    # assert output == "Hello, world!", f"Expected 'Hello, world!', got '{output}'"
    
    # Test that the binary exits successfully
    # machine.succeed("ble")
  '';
}
