{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        rust-overlay.url = "github:oxalica/rust-overlay";
        rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = inputs@{ self, ... }: with inputs;
        let
           forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.unix;
           nixpkgsFor = forAllSystems (system: import nixpkgs {
                inherit system;
                config = { };
                overlays = [ rust-overlay.overlays.default ];
            });

        in {
            devShells = forAllSystems (system:
                let pkgs = nixpkgsFor."${system}"; in {
                    default = pkgs.mkShell {
                        packages = with pkgs; [
                            (rust-bin.stable.latest.default.override {
                                extensions = [ "rust-src" "rust-analyzer" ];
                                targets = [ "thumbv7em-none-eabihf" ];
                            })
                            probe-rs-tools
                            flip-link
                            cargo-binutils
                            pkg-config
                            libusb1
                            udev
                            # Required by nrf-mpsl-sys / nrf-sdc-sys (bindgen)
                            llvmPackages.clang
                            llvmPackages.libclang.lib
                        ];
                        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
                    };
                }
            );
       };
}
