{
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
    };
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
            pname = "dsa";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = with pkgs; [
              zig
            ];

            buildPhase = ''
              runHook preBuild
              export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
              zig build -Doptimize=ReleaseSafe
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              cp zig-out/bin/main $out/bin/dsa
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Data Structures and Algorithms implementation in Zig";
              license = licenses.mit;
              platforms = platforms.all;
            };
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixpkgs-fmt
              zig
              zls
            ];

            shellHook = ''
              echo "DSA development environment"
              echo "Available commands:"
              echo "  zig build        - Build the project"
              echo "  zig build run    - Build and run"
              echo "  zig build test   - Run tests"
            '';
          };
        });

      # Legacy support
      devShell = forAllSystems (system: self.devShells.${system}.default);
    };
}
