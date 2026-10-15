#!/usr/bin/env bash
# Build the branch history: main with the plain parser, then the feature
# branch with quoted values, two review fix rounds, a remote, and the
# saved review reports under .context/review/.
set -euo pipefail
mkdir -p .context
mv review .context/review
printf '.context/\n' > .gitignore
git init -q
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -q -m "feat: validate key=value lines"
git checkout -q -b feature/quoted-values
cat > src/parse.sh <<'SRC'
#!/usr/bin/env bash
# parse <line>: print the key and the value of a "key=value" line, or fail.
# A quoted value may contain spaces.
parse() {
  local line="$1"
  [[ -z "$line" ]] && return 0
  if [[ "$line" =~ ^([a-z]*)=\"([^\"]*)\"$ ]]; then
    printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi
  [[ "$line" =~ ^([a-z]*)=([^[:space:]]*)$ ]] || return 1
  printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
}
SRC
git commit -q -am "feat(parser): accept quoted values"
sed -i.bak 's/\[a-z\]\*/[a-z]+/g' src/parse.sh && rm -f src/parse.sh.bak
cat >> README.md <<'DOC'
A value in double quotes may contain spaces: `a="1 2"`.
DOC
cat >> tests/parse_test.sh <<'TEST'
[[ "$(parse 'a="1 2"')" == "a 1 2" ]] || { echo "FAIL parse: quoted value"; exit 1; }
parse "=1" > /dev/null && { echo "FAIL parse: empty key accepted"; exit 1; }
TEST
git commit -q -am "fix(review): resolve findings 1-3"
cat >> tests/parse_test.sh <<'TEST'
[[ "$(parse 'a=""')" == "a " ]] || { echo "FAIL parse: empty quoted value"; exit 1; }
TEST
git commit -q -am "fix(review): resolve finding 4"
git init -q --bare ../origin.git
git remote add origin ../origin.git
git push -q origin main feature/quoted-values
