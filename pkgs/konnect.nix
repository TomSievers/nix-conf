# Konnect: MCP server that lets Claude Code drive KiCad 10 through its IPC API.
# Upstream ships a prebuilt glibc binary; patch it for NixOS and put kicad-cli
# (exports, ERC/DRC) and a JRE (Freerouting autorouter) on its PATH.

{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  kicad,
  jre,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "konnect";
  version = "0.13.0";

  src = fetchurl {
    url = "https://github.com/mixelpixx/Konnect/releases/download/v${finalAttrs.version}/konnect-v${finalAttrs.version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-nJ0o59kF2OhRkzmniJAZPyUryBNJkzSbQNgOOme5NRI=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 konnect $out/bin/konnect
    wrapProgram $out/bin/konnect \
      --prefix PATH : ${
        lib.makeBinPath [
          kicad
          jre
        ]
      }
    runHook postInstall
  '';

  meta = {
    description = "AI-assisted PCB design MCP server for KiCad 10";
    homepage = "https://github.com/mixelpixx/Konnect";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "konnect";
  };
})
