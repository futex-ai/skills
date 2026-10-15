# Review 3 of feature/quoted-values (re-review after fix round 2)

5. An empty line returns 0 with no output instead of 1 (src/parse.sh, the `[[ -z "$line" ]] && return 0` guard). Severity: High. Category: product bug. Effort: Small. Auto-fix: yes.
