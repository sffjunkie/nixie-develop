{pkgs, ...}:
pkgs.mkShell {
  buildInputs = [
    pkgs.alejandra
    pkgs.jq
    pkgs.nix-info
    pkgs.nix-template
    pkgs.nix-tree
    pkgs.nix-update
    pkgs.nixpkgs-fmt
    pkgs.nixpkgs-review
  ];
}
