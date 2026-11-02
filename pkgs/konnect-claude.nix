# Claude Code integration for Konnect, generated from `konnect init` at build time:
#   mcp.json  - server config for `claude --mcp-config=`, so tools keep their plain
#               mcp__konnect__* names (the bundled agents, skills and hooks expect these)
#   skills/   - to link into ~/.claude/skills
#   agents/   - to link into ~/.claude/agents
#   plugin/   - hooks-only plugin, so ~/.claude/settings.json stays user-owned

{
  runCommand,
  jq,
  konnect,
}:

runCommand "konnect-claude-${konnect.version}" { nativeBuildInputs = [ jq ]; } ''
  export HOME=$PWD/home
  mkdir -p $HOME
  ${konnect}/bin/konnect init --client claude

  mkdir -p $out/plugin/.claude-plugin $out/plugin/hooks
  cp -r $HOME/.claude/skills $HOME/.claude/agents $out/

  jq -n --arg cmd ${konnect}/bin/konnect \
    '{mcpServers: {konnect: {type: "stdio", command: $cmd}}}' > $out/mcp.json

  echo '{"name": "konnect-hooks"}' > $out/plugin/.claude-plugin/plugin.json

  # init points the hooks at the unwrapped binary; use the wrapper so kicad-cli is on PATH.
  jq --arg cmd ${konnect}/bin/konnect \
    '{hooks: .hooks} | (.. | .command? | strings) |= sub("^'"'"'[^'"'"']*'"'"'"; $cmd)' \
    $HOME/.claude/settings.json > $out/plugin/hooks/hooks.json
''
