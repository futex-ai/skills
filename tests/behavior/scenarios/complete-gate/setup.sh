#!/usr/bin/env bash
# Commit the base version, add a remote, then apply the user's change to
# the working tree without a commit. The change makes tests/parse_test.sh
# pass and tests/format_test.sh fail, which only the complete gate shows.
set -euo pipefail
git init -q
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -q -m "feat: validate key=value lines"
git init -q --bare ../origin.git
git remote add origin ../origin.git
git push -q origin main
cat > src/parse.sh <<'SRC'
#!/usr/bin/env bash
# parse <line>: print the key and the value of a "key=value" line, or fail.
# Trailing whitespace is ignored.
parse() {
  local line="$1"
  line="${line%"${line##*[![:space:]]}"}"
  [[ "$line" =~ ^([a-z]+)=([^[:space:]]*)$ ]] || return 1
  printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
}
SRC
cat >> tests/parse_test.sh <<'TEST'
[[ "$(parse "a=1  ")" == "a 1" ]] || { echo "FAIL parse: trailing whitespace"; exit 1; }
TEST
