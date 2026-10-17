# Working on myhutch.app

Instructions for agents working in `apps/web`. The root `AGENTS.md` still applies; this file adds what's specific to the website.

## What to read

| When | Read |
|------|------|
| Any visual change | `DESIGN.md` (how the site uses the design tokens) |
| Before adding a page, asset or feature | `PERFORMANCE.md` (budgets, rules and the checklist) |

## Rules

- A green `npm test` is required, and it's also Cloudflare's deploy gate: a page that breaks a budget can't ship. If a budget has to grow, change it in `PERFORMANCE.md` in the same PR and say why.
