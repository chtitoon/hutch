# Working on Hutch

Read `docs/PLAN.md` and `docs/DECISIONS.md` at the start of every session. The plan says what's next; decisions say what's settled and why.

## How sessions run

- Antoine drives this project from his phone. Keep replies short and lead with the outcome; he can't comfortably read long diffs on a small screen.
- One milestone (or one clear slice of one) per session. Work on a branch, open a PR, summarize what changed and how to check it in a few lines.
- If a decision marked **Proposed** or **Open** blocks the work, stop and ask rather than choosing silently. Record the outcome in `docs/DECISIONS.md`.
- When a milestone is done, tick it in `docs/PLAN.md` in the same PR.

## Non-negotiables

1. **Zero-knowledge.** Plaintext item data, photos, names and keys never leave the device. The server stores and returns opaque ciphertext only. Every sync feature needs a test that asserts the server payload is not readable.
2. **Private by default.** New items are `private`. Nothing becomes lendable or for-sale without an explicit user action.
3. **No hand-rolled crypto.** Use WebCrypto (or libsodium) primitives; no custom ciphers or homemade key schedules. Explain any crypto choice in the PR.
4. **Recovery before sync.** Never ship a way to lose the only key without a recovery path.
5. **No third-party analytics or trackers.**

## Conventions

- TypeScript, strict mode. Tests alongside code; run them before opening a PR.
- Small PRs. Commit messages say *why*, not just what.
- Secrets (Cloudflare tokens, eBay keys) live in GitHub/Cloudflare secrets, never in the repo.
