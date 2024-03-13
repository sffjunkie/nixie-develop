{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  nixConfig = {
    bash-prompt = ''\n\[\033[1;34m\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] '';
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    lib = nixpkgs.lib.extend (import ./lib {inherit lib;});

    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      trino = pkgs.callPackage ./pkgs/trino.nix {};
    });

    nixosModules = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      trino = import ./modules/trino.nix {pkgs = pkgs // self.packages;};
    });

    # Generic development shells
    # The default 'nix' shell includes scripts to build systems
    # using nix-ouptut-monitor
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = import ./devshell/nix {inherit pkgs;};
    });
  };
}
