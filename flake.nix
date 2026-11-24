{
  description = "Dotfiles toolchain: stow and node for the checks";

  # nixpkgs-unstable dropped x86_64-darwin (26.11), so this shell is Linux-only.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          stow
          nodejs
        ];
      };
    };
}
