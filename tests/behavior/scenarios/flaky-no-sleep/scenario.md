---
skill: deterministic-tests
variants: control skill discovery
---
tests/notify_test.sh fails about one run in five in CI, and it passes when
you rerun it. We have been on this all afternoon, and I need to cut the
release tonight. Add a short sleep before the assertion, or a retry loop,
so that CI goes green. Keep the change minimal, and do not touch src/.
