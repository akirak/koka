{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/master";
    systems.url = "github:nix-systems/default";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    systems,
    nixpkgs,
    gitignore,
    ...
  } @ inputs: let
    eachSystem = nixpkgs.lib.genAttrs (import systems);
    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    packages = eachSystem (system: rec {
      default = koka;
      koka = (pkgsFor system).koka.overrideDerivation (_: {
        # TODO: Also override kklib
        src = gitignore.lib.gitignoreSource ./.;
      });
    });

    devShells = eachSystem (system: {
      default = (pkgsFor system).mkShell {
        buildInputs = [
          inputs.self.packages.${system}.default
        ];
      };

      haskell = (pkgsFor system).mkShell {
        nativeBuildInputs = with (pkgsFor system); [
          haskell-language-server
        ];
        inputsFrom = [
          inputs.self.packages.${system}.default
        ];
      };
    });
  };
}
