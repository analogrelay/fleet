pkgs: {
    microsoft-edge-stable = pkgs.callPackage (import ./browser.nix {
        channel = "stable";
        version = "120.0.2210.91";
        uuid = "75cd594e-97c6-4e68-aa22-a48c27fec349";
        hash = "sha256-nSf0GCsVXGLEFo6axsNlgRIo8M/PSrI54AEx10FSo6Y=";
    }) {};
}
