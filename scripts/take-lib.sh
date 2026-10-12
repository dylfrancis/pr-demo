# Sourced by a pr-demo take script. Needs SESSION and OUT set.
set -Eeuo pipefail
: "${SESSION:?set SESSION to the agent-browser session}" "${OUT:?set OUT to the output directory}"

ab() { agent-browser --session "$SESSION" "$@"; }

# Type into the focused element one key at a time (~80 ms per key), so the viewer sees it typed.
slowtype() {
  local s=$1 i
  for ((i = 0; i < ${#s}; i++)); do ab keyboard type "${s:i:1}" >/dev/null; done
}

# A failed step must not leave the recording running, or the next take fails with "Recording already active".
trap 'ab record stop >/dev/null 2>&1 || true' ERR

# Glide the pointer to the element with this role and accessible name, as a snapshot shows them, then click it.
# `find ... click` teleports the pointer; this moves it on an eased curve the viewer can follow.
#   glide button "Save"        glide link "Settings" 1000   (optional duration in ms, default 700)
glide() {
  local role=$1 name=$2 ms=${3:-700} ref x y
  ref=$(ab snapshot -i --json | jq -r --arg r "$role" --arg n "$name" \
    '[.data.refs | to_entries[] | select(.value.role == $r and .value.name == $n) | .key] | first // empty')
  [[ -n $ref ]] || { echo "glide: no $role named \"$name\"" >&2; return 1; }
  read -r x y < <(ab get box "@$ref" --json | jq -r '.data | "\(.x + .width / 2 | floor) \(.y + .height / 2 | floor)"')
  ab mouse move "$x" "$y" --human --duration "$ms" >/dev/null
  ab click "@$ref" >/dev/null
}
