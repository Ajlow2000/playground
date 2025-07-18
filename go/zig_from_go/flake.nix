{
  description = "Go application flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "go-app";
            version = "0.1.0";
            src = ./.;
            
            nativeBuildInputs = [ pkgs.go pkgs.zig ];
            
            buildPhase = ''
              export HOME=$TMPDIR
              
              # Build Zig library
              echo "Building Zig library..."
              cd lib
              zig build-lib -O ReleaseFast -static hello.zig
              cd ..
              
              # Build Go application
              echo "Building Go application..."
              go build -o zig_from_go .
              
              echo "Build complete!"
            '';
            
            installPhase = ''
              mkdir -p $out/bin
              cp zig_from_go $out/bin/
            '';
            
            meta = with pkgs.lib; {
              description = "Go application with Zig interop";
              license = licenses.mit;
              maintainers = [ ];
            };
          };
        });

      checks = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          test = pkgs.stdenv.mkDerivation {
            name = "go-test";
            src = ./.;
            buildInputs = [ pkgs.go pkgs.zig ];
            buildPhase = ''
              export HOME=$TMPDIR
              # Build Zig library first
              mkdir -p lib
              zig build-lib -O ReleaseFast -static lib/hello.zig
              mv libhello.a lib/
              # Run Go tests
              go test ./...
            '';
            installPhase = ''
              touch $out
            '';
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              go
              gopls
              gotools
              go-tools
              zig
            ];
            
            shellHook = ''
              echo "Go development environment: $(go version)"
            '';
          };
        });
    };
}
