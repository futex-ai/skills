#!/usr/bin/env bash
# The agent homes and commands for tests/behavior/run.sh. run.sh sources
# this file; do not run it. It uses the variables that run.sh sets:
# real_home, budget, model, timeout_s, sc_skill, and argv.
#
# Each run gets a temporary home. Only the authentication, the settings
# without hooks, and the always-on rules are copied into it, so installed
# skills stay out. The variant then appends the skill text to the rules
# (skill), links the skill as an installed skill (discovery), or adds
# nothing (control). After the run, the authentication is removed from
# the kept home.
# shellcheck shell=bash disable=SC2154

copy_if_present() {  # copy_if_present <source> <target>: copy a file, following links
  if [[ -f "$1" ]]; then cp -L "$1" "$2"; fi
}

make_home() {  # make_home <run dir> <agent> <variant> <skill dir>
  local home="$1/home" src rules
  mkdir -p "$home/.claude" "$home/.codex"
  printf '[user]\n\tname = behavior\n\temail = behavior@example.com\n[init]\n\tdefaultBranch = main\n' \
    > "$home/.gitconfig"
  if [[ "$2" == claude ]]; then
    src="${CLAUDE_CONFIG_DIR:-$real_home/.claude}"
    if [[ -f "$src/settings.json" ]]; then
      jq 'del(.hooks)' "$src/settings.json" > "$home/.claude/settings.json"
    fi
    copy_if_present "$src/.credentials.json" "$home/.claude/.credentials.json"
    if [[ -f "$src/.claude.json" ]]; then
      cp "$src/.claude.json" "$home/.claude/.claude.json"
    else
      copy_if_present "$real_home/.claude.json" "$home/.claude/.claude.json"
    fi
    rules="$home/.claude/CLAUDE.md"
    copy_if_present "$src/CLAUDE.md" "$rules"
  else
    src="${CODEX_HOME:-$real_home/.codex}"
    copy_if_present "$src/auth.json" "$home/.codex/auth.json"
    copy_if_present "$src/config.toml" "$home/.codex/config.toml"
    rules="$home/.codex/AGENTS.md"
    copy_if_present "$src/AGENTS.md" "$rules"
  fi
  case "$3" in
    skill)
      if [[ -f "$rules" ]]; then echo >> "$rules"; fi
      {
        echo "# Skill in effect: $sc_skill"
        echo
        echo "The files of this skill are under $4."
        echo
        body "$4/SKILL.md"
      } >> "$rules"
      ;;
    discovery)
      mkdir -p "$home/.claude/skills" "$home/.codex/skills"
      ln -s "$4" "$home/.claude/skills/$sc_skill"
      ln -s "$4" "$home/.codex/skills/$sc_skill"
      ;;
  esac
}

strip_credentials() {  # strip_credentials <home>: remove the copied authentication from a kept home
  local settings="$1/.claude/settings.json"
  rm -f "$1/.claude/.credentials.json" "$1/.codex/auth.json"
  if [[ -f "$settings" ]]; then
    jq 'del(.apiKeyHelper, .env)' "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
  fi
}

agent_argv() {  # agent_argv <run dir> <agent> <variant>: set argv to the command of the run
  local home="$1/home"
  argv=(env -u CLAUDECODE "HOME=$home" "CLAUDE_CONFIG_DIR=$home/.claude" "CODEX_HOME=$home/.codex")
  if [[ "$2" == claude ]]; then
    argv+=(claude -p --output-format stream-json --verbose --no-session-persistence
      --permission-mode acceptEdits --permission-prompts none
      --allowedTools "Bash Read Edit Write Glob Grep" --max-budget-usd "$budget")
    if [[ -n "$model" ]]; then argv+=(--model "$model"); fi
    if [[ "$3" != discovery ]]; then argv+=(--disable-slash-commands); fi
  else
    argv+=(codex exec -C "$1/workspace" --skip-git-repo-check --ephemeral --json --color never
      --sandbox workspace-write --output-last-message "$1/final.md")
    if [[ -n "$model" ]]; then argv+=(--model "$model"); fi
    argv+=(-)
  fi
}

timeout_cmd() {  # the timeout command with its limit, or nothing when none is on PATH
  local cmd
  for cmd in timeout gtimeout; do
    if command -v "$cmd" > /dev/null 2>&1; then printf '%s %s' "$cmd" "$timeout_s"; return; fi
  done
}

run_agent() {  # run_agent <run dir>: run argv in the workspace with the prompt on stdin; print the status
  local status=0 limit
  limit="$(timeout_cmd)"
  # shellcheck disable=SC2086
  (cd "$1/workspace" && $limit "${argv[@]}" < "$1/prompt.md" > "$1/transcript.jsonl" 2> "$1/stderr.log") \
    || status=$?
  case "$status" in
    0) echo ok ;;
    124) echo timeout ;;
    *) echo "exit $status" ;;
  esac
}
