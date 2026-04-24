{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libusb1,
  stdenv,
  apple-sdk_15,
  darwin,
  writableTmpDirAsHomeHook,
}:

rustPlatform.buildRustPackage {
  pname = "display-switch";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "haimgel";
    repo = "display-switch";
    rev = "8b8e8cdf9c48c60749347c45d26bfdad68742ae8";
    hash = "sha256-zHm09av/t4QxtwrSkGTtA4JWqHaVZ76Qibd86les6xQ=";
  };

  cargoHash = "sha256-dVrctqemTcGau+zCUyCoOZC8xHSbCbTMp5RtK4n5FyQ=";

  nativeBuildInputs =
    [ pkg-config ]
    ++ lib.optionals stdenv.isDarwin [
      # Provides sw_vers, which libusb1-sys build script needs to detect the
      # macOS version (not in PATH in the Nix sandbox otherwise).
      darwin.DarwinTools
    ];

  buildInputs =
    [ libusb1 ]
    ++ lib.optionals stdenv.isDarwin [
      apple-sdk_15
    ];

  # vergen-git2 tries to read .git metadata at build time; tell it to use
  # placeholders instead of failing inside the Nix sandbox.
  VERGEN_IDEMPOTENT = "true";

  # test_log_file_name resolves $HOME to build the log path; provide a
  # writable temp dir so the check doesn't fail in the Nix sandbox.
  nativeCheckInputs = [ writableTmpDirAsHomeHook ];

  meta = with lib; {
    description = "Switch monitor inputs based on USB device connect/disconnect events (DDC/CI)";
    homepage = "https://github.com/haimgel/display-switch";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "display_switch";
  };
}
