# ESLint guard for elapsed-time assertions

Apply `no-restricted-syntax` to every JavaScript and TypeScript file under
the test tree, including browser specs. Exempt only the shared
duration-reporting helper, which is the one module allowed to subtract clock
reads. Product and script code stay outside the guard.

The guard rejects two patterns, including inside a `page.evaluate` callback:

- A subtraction with a clock call on the left and a nonliteral operand on
  the right. Clock calls are `performance.now()`, `Date.now()`, and
  `process.hrtime.bigint()`.
- `performance.now()` or `Date.now()` plus a number literal below 10,000.

Selectors:

```text
BinaryExpression[operator='-'][right.type!='Literal']:matches([left.type='CallExpression'][left.callee.property.name='now'][left.callee.object.name=/^(performance|Date)$/], [left.callee.property.name='bigint'][left.callee.object.property.name='hrtime'])
BinaryExpression[operator='+'][left.callee.property.name='now'][left.callee.object.name=/^(performance|Date)$/][right.type='Literal'][right.value<10000]
```

Deadlines of 10,000 ms or more, deadline comparisons, and literal timestamp
offsets stay allowed: `performance.now() + 20_000`,
`performance.now() < deadline`, `new Date(Date.now() - 10_000)`. Variable
deadlines such as `Date.now() + timeoutMs` pass the syntax check but must
still allow at least 10 seconds when polling for an expected state. Indirect
calls such as `clock() - started` pass the selectors and must still follow
the assertion rule.

Make the lint message name the rule's doc. Test the rule with
`ESLint.lintText` on rejected and allowed forms in each scoped path.

## Shared helpers worth adding

- An operation-counting helper that wraps `fs.statSync`, `fs.lstatSync`,
  `fs.existsSync`, `fs.readdirSync`, `fs.realpathSync` (keeping its counted
  `native` method), `path.relative`, `path.resolve`, and
  `Array.prototype.sort` for one synchronous callback. It records totals and
  per-first-path counts, restores every original on return or throw, rejects
  nested calls, and fails a callback that returns a thenable because async
  work can escape the counting window. Pair it with a two-size assertion
  that applies the acceptance relations from the skill. Counted code must
  call `fs` and `path` through their default imports; a named import escapes
  the wrappers, and the positive smaller-size count catches that.
- A duration-reporting helper that returns the callback's result, reports
  the duration once as text with one decimal place and ` ms`, exposes no
  numeric duration, and lets the callback's error take precedence over a
  reporter error.
