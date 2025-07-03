{
    description = "A bindgen demo.";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    outputs = { self, nixpkgs }:
        let
            supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
            forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

            pkgs = nixpkgs.legacyPackages.x86_64-linux;

            packages = with pkgs; [
                llvmPackages.libclang
            ];

        in
            {
            defaultPackage = forAllSystems (system: (import nixpkgs {
                inherit system;
                overlays = [ self.overlay ];
            }).doggo);

            overlay = final: prev: {
                doggo = final.callPackage ./. { };
            };

            devShells.default = pkgs.mkShell {
                buildInputs = packages;
                # nativeBuildInputs = nativeBuildPackages;
                shellHook = with pkgs; ''
                        export LD_LIBRARY_PATH="${
                    lib.makeLibraryPath libraries
                }:$LD_LIBRARY_PATH"
                        export OPENSSL_INCLUDE_DIR="${openssl.dev}/include/openssl"
                        export OPENSSL_LIB_DIR="${openssl.out}/lib"
                        export OPENSSL_ROOT_DIR="${openssl.out}"
                        export RUST_SRC_PATH="${toolchain}/lib/rustlib/src/rust/library"
                        export LIBCLANG_PATH="${llvmPackages.libclang.lib}/lib"
                        export BINDGEN_EXTRA_CLANG_ARGS="$(< ${stdenv.cc}/nix-support/libc-crt1-cflags) \
                            $(< ${stdenv.cc}/nix-support/libc-cflags) \
                            $(< ${stdenv.cc}/nix-support/cc-cflags) \
                            $(< ${stdenv.cc}/nix-support/libcxx-cxxflags) \
                    ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
                    ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${lib.getVersion stdenv.cc.cc}/include"} \
                        "
                '';
            };
        };
}

