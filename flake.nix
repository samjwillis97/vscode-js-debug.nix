{
  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "dream2nix/nixpkgs";
  };

  nixConfig = {
    extra-substituters = ["https://vscode-js-debug.cachix.org"];
    extra-trusted-public-keys = ["vscode-js-debug.cachix.org-1:R9DqPqQ4TZxvhStSu5v+6KcJ548NkUBXUVonqtkLl8g="];
  };

  outputs = {
    dream2nix,
    flake-utils,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
    };

    pythonEnv = pkgs.python3.withPackages (ps: with ps; [semver]);
  in {
    apps.${system}.update-sources = flake-utils.lib.mkApp {
      drv = pkgs.callPackage ./scripts/update-sources {inherit pythonEnv;};
    };

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [niv pythonEnv ruff-lsp];
    };

    packages.${system} = let
      sources = import ./nix/sources.nix {};
      mkName = lib.replaceStrings ["."] ["-"];
      mkPackage = version: src:
        dream2nix.lib.evalModules {
          packageSets.nixpkgs = pkgs;
          modules = [
            {
              config.deps.src = src;
              config.deps.version = version;
            }
            ./default.nix
            {
              paths.projectRoot = ./.;
              paths.projectRootFile = "flake.nix";
              paths.package = ./.;
            }
          ];
        };
    in
      lib.mapAttrs' (
        version: src:
          lib.nameValuePair (mkName version) (mkPackage version src)
      )
      sources;
  };
}
