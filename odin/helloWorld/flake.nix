{
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};

      pname = "helloWorld";
      version = "0.1.0";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.stdenv.mkDerivation {
            inherit pname version;
            src = ./.;

            nativeBuildInputs = with pkgs; [
              odin
            ];

            buildPhase = ''
              runHook preBuild
              odin build . -out:${pname}
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              cp ${pname} $out/bin/${pname}
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Hello World application written in Odin";
              license = licenses.gpl3;
              platforms = platforms.all;
            };
          };
        }
      );

      # checks = forAllSystems (
      #   system:
      #   let
      #     pkgs = pkgsFor system;
      #   in
      #   {
      #     build = pkgs.stdenv.mkDerivation {
      #       inherit pname version;
      #       src = ./.;
      #
      #       nativeBuildInputs = with pkgs; [
      #         odin
      #       ];
      #
      #       buildPhase = ''
      #         runHook preBuild
      #         odin build . -out:${pname}
      #         runHook postBuild
      #       '';
      #
      #       installPhase = ''
      #         runHook preInstall
      #         mkdir -p $out
      #         echo "Build successful" > $out/build-results
      #         runHook postInstall
      #       '';
      #     };
      #   }
      # );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixpkgs-fmt
              odin
            ];

            shellHook = ''
              echo "Odin development environment (odin version $(odin version))"
              echo "Available commands:"
              echo "  odin build .     - Build the project"
              echo "  odin run .       - Build and run"
              echo "  nix build        - Build using Nix"
            '';
          };
        }
      );

      devShell = forAllSystems (system: self.devShells.${system}.default);
    };
}
