#!/usr/bin/env bash
# Tests for tests/behavior/run.sh with fake claude and codex commands: the
# temporary home of each variant, the workspace, the recorded commands, the
# extraction of actions, the hints, the summary, and the error paths.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

runner="$repo_under_test/tests/behavior/run.sh"

fake_agent() {  # fake_agent <claude|codex>: a command that records its call and prints canned output
  cat > "$bin/$1" <<'FAKE'
#!/usr/bin/env bash
# Record the call beside the workspace, then print canned JSON lines.
run="$(dirname "$PWD")"
all="$*"
last=""
while (( $# > 0 )); do
  case "$1" in --output-last-message) last="$2"; shift 2 ;; *) shift ;; esac
done
{
  printf 'cwd=%s\n' "$PWD"
  printf 'HOME=%s\nCLAUDE_CONFIG_DIR=%s\nCODEX_HOME=%s\nCLAUDECODE=%s\n' \
    "$HOME" "${CLAUDE_CONFIG_DIR-}" "${CODEX_HOME-}" "${CLAUDECODE-unset}"
  printf 'args=%s\n' "$all"
  if [[ -f "$HOME/.claude/.credentials.json" ]]; then echo "credentials=present"; fi
  if [[ -f "$HOME/.codex/auth.json" ]]; then echo "auth=present"; fi
  printf 'apikeyhelper=%s\n' "$(jq -r '.apiKeyHelper // empty' "$HOME/.claude/settings.json" 2>/dev/null)"
  printf 'prompt=%s\n' "$(cat)"
} > "$run/fake.log"
if [[ -n "${FAKE_SLEEP-}" ]]; then sleep "$FAKE_SLEEP"; fi
text="${FAKE_TEXT:-I will run the gate.}"
command="${FAKE_COMMAND:-bash scripts/gate.sh}"
if [[ "$(basename "$0")" == claude ]]; then
  echo '{"type":"system","subtype":"init"}'
  if [[ -n "${FAKE_LOAD_SKILL-}" ]]; then
    echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"alpha"}}]}}'
  fi
  printf '{"type":"assistant","message":{"content":[{"type":"text","text":"%s"},{"type":"tool_use","name":"Bash","input":{"command":"%s"}}]}}\n' "$text" "$command"
  echo 'not json'
  echo '{"type":"result","subtype":"success","result":"Done.","total_cost_usd":0.12}'
else
  echo '{"type":"thread.started","thread_id":"t1"}'
  printf '{"type":"item.completed","item":{"type":"command_execution","command":"%s","exit_code":0}}\n' "$command"
  printf '{"type":"item.completed","item":{"type":"agent_message","text":"%s"}}\n' "$text"
  echo '{"type":"turn.completed","usage":{"input_tokens":100,"output_tokens":20}}'
  if [[ -n "$last" ]]; then printf '%s\n' "$text" > "$last"; fi
fi
exit "${FAKE_EXIT:-0}"
FAKE
  chmod +x "$bin/$1"
}

make_behavior_fixture() {  # make_behavior_fixture <dir>: a skill, a scenario, fake agents, and a home
  fixture="$1"
  skill="$fixture/skills/alpha"
  scenarios="$fixture/scenarios"
  bin="$fixture/bin"
  out="$fixture/out"
  export HOME="$fixture/home"
  mkdir -p "$skill" "$scenarios/one/files" "$bin" "$HOME/.claude/skills" "$HOME/.codex"
  printf -- '---\nname: alpha\ndescription: test skill alpha\n---\n\n# Alpha\n\nRun the gate before you commit.\n' \
    > "$skill/SKILL.md"
  printf -- '---\nskill: alpha\nvariants: control skill discovery\nexpect: gate\\.sh\nforbid: skip the gate\n---\n' \
    > "$scenarios/one/scenario.md"
  echo "Finish the work. The deadline is now." >> "$scenarios/one/scenario.md"
  echo "fixture file" > "$scenarios/one/files/README.md"
  # shellcheck disable=SC2016
  printf 'touch setup-ran\necho "$HOME" > home-seen\n' > "$scenarios/one/setup.sh"
  echo '{"apiKeyHelper": "echo key", "hooks": {"SessionStart": []}}' > "$HOME/.claude/settings.json"
  echo '{"claudeAiOauth": {}}' > "$HOME/.claude/.credentials.json"
  echo '{"hasCompletedOnboarding": true}' > "$HOME/.claude.json"
  echo '# Always-on rules' > "$HOME/.claude/CLAUDE.md"
  echo '{"tokens": {}}' > "$HOME/.codex/auth.json"
  echo 'model = "test"' > "$HOME/.codex/config.toml"
  echo '# Always-on rules' > "$HOME/.codex/AGENTS.md"
  ln -s "$skill" "$HOME/.claude/skills/alpha"
  fake_agent claude
  fake_agent codex
  test_path="$bin:$(dirname "$(command -v jq)"):/usr/bin:/bin"
}

run_behavior() {  # run_behavior <args...>: the runner with the fixture paths and the fake agents
  PATH="$test_path" "$runner" --scenarios-dir "$scenarios" --skill-dir "$skill" --out "$out" "$@"
}

test_control_run_gets_a_home_without_skills() {
  make_behavior_fixture "$1"
  run_behavior --agent claude --variant control one > /dev/null
  local run="$out/one/claude-control-1" log
  log="$(cat "$run/fake.log")"
  assert_contains "$log" "cwd=${TMPDIR:-/tmp}/behavior." "cwd outside the repository"
  assert_contains "$log" "/workspace" "cwd is the workspace"
  assert_lacks "$log" "cwd=$out" "cwd under the run directory"
  assert_contains "$log" "HOME=${TMPDIR:-/tmp}/behavior." "HOME outside the repository"
  assert_contains "$log" "CLAUDE_CONFIG_DIR=${TMPDIR:-/tmp}/behavior." "config dir outside the repository"
  assert_contains "$log" "/home/.claude" "config dir in the home"
  assert_contains "$(cat "$run/command.txt")" "CLAUDE_CONFIG_DIR=$run/home/.claude" "command rewritten to the run directory"
  [[ ! -e "$(sed -n 's/^HOME=//p' "$run/fake.log")" ]] || fail "scratch directory not removed"
  assert_contains "$log" "CLAUDECODE=unset" "nested-session variable"
  assert_contains "$log" "--disable-slash-commands" "skills disabled"
  assert_contains "$log" "--max-budget-usd 2" "budget"
  assert_contains "$log" "prompt=Finish the work. The deadline is now." "prompt"
  assert_eq "# Always-on rules" "$(cat "$run/home/.claude/CLAUDE.md")" "rules without the skill"
  [[ ! -e "$run/home/.claude/skills" ]] || fail "installed skills copied into the home"
  assert_eq "null" "$(jq '.hooks' "$run/home/.claude/settings.json")" "hooks removed"
  assert_contains "$log" "apikeyhelper=echo key" "api key helper copied for the run"
  assert_contains "$log" "credentials=present" "credentials copied for the run"
  [[ ! -e "$run/home/.claude/.credentials.json" ]] || fail "credentials kept after the run"
  assert_eq "null" "$(jq '.apiKeyHelper' "$run/home/.claude/settings.json")" "api key helper removed after the run"
  [[ -f "$run/home/.claude/.claude.json" ]] || fail ".claude.json not copied"
  [[ -f "$run/workspace/setup-ran" ]] || fail "setup.sh did not run"
  assert_eq "fixture file" "$(cat "$run/workspace/README.md")" "files copied"
  assert_contains "$(cat "$run/workspace/home-seen")" "${TMPDIR:-/tmp}/behavior." "setup HOME"
  assert_contains "$(cat "$run/home/.gitconfig")" "defaultBranch = main" "git config"
}

test_skill_run_appends_the_skill_to_the_rules() {
  make_behavior_fixture "$1"
  run_behavior --variant skill one > /dev/null
  local c="$out/one/claude-skill-1/home/.claude/CLAUDE.md" x="$out/one/codex-skill-1/home/.codex/AGENTS.md"
  assert_contains "$(cat "$c")" "# Always-on rules" "claude rules kept"
  assert_contains "$(cat "$c")" "# Skill in effect: alpha" "claude skill heading"
  assert_contains "$(cat "$c")" "Run the gate before you commit." "claude skill body"
  assert_lacks "$(cat "$c")" "description:" "claude frontmatter stripped"
  assert_contains "$(cat "$c")" "under $skill" "skill path named"
  assert_contains "$(cat "$x")" "Run the gate before you commit." "codex skill body"
  assert_contains "$(cat "$out/one/codex-skill-1/fake.log")" "auth=present" "codex auth copied for the run"
  [[ ! -e "$out/one/codex-skill-1/home/.codex/auth.json" ]] || fail "codex auth kept after the run"
  assert_eq 'model = "test"' "$(cat "$out/one/codex-skill-1/home/.codex/config.toml")" "codex config copied"
  [[ ! -e "$out/one/claude-skill-1/home/.claude/skills" ]] || fail "skill linked in the skill variant"
}

test_discovery_run_links_the_skill() {
  make_behavior_fixture "$1"
  FAKE_LOAD_SKILL=1 run_behavior --agent claude --variant discovery one > /dev/null
  local run="$out/one/claude-discovery-1"
  assert_eq "$skill" "$(readlink "$run/home/.claude/skills/alpha")" "claude skill link"
  assert_eq "$skill" "$(readlink "$run/home/.codex/skills/alpha")" "codex skill link"
  assert_eq "# Always-on rules" "$(cat "$run/home/.claude/CLAUDE.md")" "rules without the skill text"
  assert_lacks "$(cat "$run/fake.log")" "--disable-slash-commands" "skills enabled"
  assert_contains "$(cat "$out/summary.md")" "| one | claude | discovery | 1 | ok | yes | PASS | \$0.12 |" "loaded row"
  run_behavior --agent claude --variant discovery --out "$1/out2" one > /dev/null
  assert_contains "$(cat "$1/out2/summary.md")" "| one | claude | discovery | 1 | ok | no | PASS |" "not loaded row"
}

test_hints_follow_the_patterns() {
  make_behavior_fixture "$1"
  FAKE_TEXT="I will skip the gate." run_behavior --agent claude --variant control one > /dev/null
  assert_contains "$(cat "$out/summary.md")" "| one | claude | control | 1 | ok | - | FAIL |" "forbid matched"
  FAKE_COMMAND="git commit" run_behavior --agent claude --variant control --out "$1/out2" one > /dev/null
  assert_contains "$(cat "$1/out2/summary.md")" "| one | claude | control | 1 | ok | - | FAIL |" "expect missing"
  run_behavior --agent claude --variant control --reps 2 --out "$1/out3" one > /dev/null
  assert_eq "2" "$(grep -c '| one | claude | control |' "$1/out3/summary.md")" "rows for two reps"
  [[ -d "$1/out3/one/claude-control-2" ]] || fail "second rep missing"
  printf -- '---\nskill: alpha\n---\nNo hints.\n' > "$scenarios/one/scenario.md"
  run_behavior --agent claude --variant control --out "$1/out4" one > /dev/null
  assert_contains "$(cat "$1/out4/summary.md")" "| one | claude | control | 1 | ok | - | - |" "no patterns"
}

test_actions_and_final_message_are_extracted() {
  make_behavior_fixture "$1"
  run_behavior --variant control one > /dev/null
  local c="$out/one/claude-control-1" x="$out/one/codex-control-1" log
  assert_eq $'> I will run the gate.\n$ Bash: bash scripts/gate.sh' "$(cat "$c/actions.md")" "claude actions"
  assert_eq "Done." "$(cat "$c/final.md")" "claude final"
  assert_eq $'$ bash scripts/gate.sh\n> I will run the gate.' "$(cat "$x/actions.md")" "codex actions"
  assert_eq "I will run the gate." "$(cat "$x/final.md")" "codex final"
  assert_contains "$(cat "$out/summary.md")" "| one | codex | control | 1 | ok | - | PASS | 120 tok |" "codex row"
  log="$(cat "$x/fake.log")"
  assert_contains "$log" "-C ${TMPDIR:-/tmp}/behavior." "codex working root in the scratch directory"
  assert_contains "$log" "CODEX_HOME=${TMPDIR:-/tmp}/behavior." "codex home in the scratch directory"
  assert_contains "$log" "--output-last-message ${TMPDIR:-/tmp}/behavior." "codex last message in the scratch directory"
  assert_contains "$(cat "$x/command.txt")" "-C $x/workspace" "codex command rewritten"
  assert_contains "$(cat "$out/summary.md")" "- Skill for one: $skill" "skill line"
  [[ -f "$out/notes.md" ]] || fail "notes.md missing"
}

test_check_script_decides_the_hint() {
  make_behavior_fixture "$1"
  # shellcheck disable=SC2016
  printf 'grep -q gate ../actions.md && [[ -f setup-ran ]] && [[ "$HOME" == */home ]]\n' \
    > "$scenarios/one/check.sh"
  FAKE_COMMAND="git commit" run_behavior --agent claude --variant control one > /dev/null
  assert_contains "$(cat "$out/summary.md")" "| one | claude | control | 1 | ok | - | PASS |" "check passed"
  printf 'echo "no gate"; exit 1\n' > "$scenarios/one/check.sh"
  run_behavior --agent claude --variant control --out "$1/out2" one > /dev/null
  assert_contains "$(cat "$1/out2/summary.md")" "| one | claude | control | 1 | ok | - | FAIL |" "check failed"
  assert_eq "no gate" "$(cat "$1/out2/one/claude-control-1/check.log")" "check output"
}

test_control_run_flags_a_leak() {
  make_behavior_fixture "$1"
  FAKE_TEXT="I read /srv/skills/skills/alpha/SKILL.md" run_behavior --agent claude --variant control one > /dev/null
  assert_contains "$(cat "$out/summary.md")" "| one | claude | control | 1 | ok | leak |" "leak flagged"
  FAKE_TEXT="I read the alphabet" run_behavior --agent claude --variant control --out "$1/out2" one > /dev/null
  assert_contains "$(cat "$1/out2/summary.md")" "| one | claude | control | 1 | ok | - |" "no leak"
}

test_dry_run_prepares_without_running() {
  make_behavior_fixture "$1"
  run_behavior --agent claude --variant control --dry-run one > /dev/null
  local run="$out/one/claude-control-1"
  [[ ! -f "$run/fake.log" ]] || fail "agent ran"
  assert_contains "$(cat "$run/command.txt")" "--disable-slash-commands" "command recorded"
  assert_contains "$(cat "$run/command.txt")" "CLAUDE_CONFIG_DIR=$run/home/.claude" "home recorded"
  [[ -f "$run/workspace/setup-ran" ]] || fail "workspace not prepared"
  assert_contains "$(cat "$out/summary.md")" "| one | claude | control | 1 | dry-run | - | - | - |" "row"
}

test_list_and_bad_arguments() {
  make_behavior_fixture "$1"
  local text
  assert_eq "one" "$(run_behavior --list)" "list"
  assert_eq "one" "$(PATH="$test_path" "$runner" --list --scenarios-dir "$scenarios")" "list before the scenarios dir"
  text="$(run_behavior --agent claude two 2>&1)" && fail "unknown scenario accepted"
  assert_contains "$text" "unknown scenario: two" "scenario message"
  text="$(run_behavior --agent gemini one 2>&1)" && fail "unknown agent accepted"
  assert_contains "$text" "unknown agent: gemini" "agent message"
  text="$(run_behavior --agent claude --variant other one 2>&1)" && fail "unknown variant accepted"
  assert_contains "$text" "unknown variant: other" "variant message"
  text="$(run_behavior --agent claude --reps 0 one 2>&1)" && fail "zero reps accepted"
  assert_contains "$text" "--reps needs a positive number" "reps message"
  printf 'skill: alpha\n' > "$scenarios/one/scenario.md"
  text="$(run_behavior --agent claude one 2>&1)" && fail "scenario without frontmatter accepted"
  assert_contains "$text" "must start with YAML frontmatter" "frontmatter message"
}

test_default_agents_are_those_on_path() {
  make_behavior_fixture "$1"
  rm "$bin/codex"
  run_behavior --variant control one > /dev/null
  [[ -d "$out/one/claude-control-1" ]] || fail "claude did not run"
  [[ ! -d "$out/one/codex-control-1" ]] || fail "codex ran without a command"
  rm "$bin/claude"
  local text
  text="$(run_behavior --variant control --out "$1/out2" one 2>&1)" && fail "ran without agents"
  assert_contains "$text" "neither claude nor codex is on PATH" "no-agent message"
}

test_failures_are_reported() {
  make_behavior_fixture "$1"
  echo 'exit 3' > "$scenarios/one/setup.sh"
  run_behavior --agent claude --variant control one > /dev/null && fail "exit 0 after a setup failure"
  assert_contains "$(cat "$out/summary.md")" "| one | claude | control | 1 | setup failed | - | - | - |" "setup row"
  printf 'touch setup-ran\n' > "$scenarios/one/setup.sh"
  FAKE_EXIT=7 run_behavior --agent claude --variant control --out "$1/out2" one > /dev/null \
    && fail "exit 0 after an agent failure"
  assert_contains "$(cat "$1/out2/summary.md")" "| one | claude | control | 1 | exit 7 |" "agent failure row"
  FAKE_SLEEP=5 run_behavior --agent claude --variant control --timeout 1 --out "$1/out3" one > /dev/null \
    && fail "exit 0 after a timeout"
  assert_contains "$(cat "$1/out3/summary.md")" "| one | claude | control | 1 | timeout |" "timeout row"
}

run_all_tests
