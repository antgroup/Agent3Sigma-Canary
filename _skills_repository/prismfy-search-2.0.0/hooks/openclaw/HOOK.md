---
name: prismfy-search-default
description: "Registers Prismfy as the default web search tool on every agent boot"
metadata: {"openclaw":{"emoji":"🔍","events":["agent:bootstrap"]}}
---

# 🔍 Prismfy Search — Ready

You have **Prismfy Search** available. Use it whenever you need live information from the web.

## How to search

```bash
bash search.sh "your query here"
```

With options:
```bash
bash search.sh --engine brave "query"        # general web (free)
bash search.sh --engine bing "query"         # news & broad coverage (paid)
bash search.sh --engine reddit "query"       # community opinions & discussions
bash search.sh --engine github "query"       # code, repos, issues
bash search.sh --engine hackernews "query"   # tech community, startups
bash search.sh --engine arxiv "query"        # academic papers, research
bash search.sh --engines brave,bing "query"  # multiple engines at once
bash search.sh --time week "query"           # filter to last 7 days
bash search.sh --domain github.com "query"  # search within a specific site
bash search.sh --quota                       # check remaining quota
```

## When to search

Prefer real search results over training data whenever the answer might have changed or needs to be current:

| Situation | Recommended |
|-----------|-------------|
| Recent news or events | search first |
| Library versions, API docs, changelogs | search first |
| Community opinions (Reddit, HN) | search first |
| Code examples, GitHub repos | search first |
| Academic papers | search first |
| Pricing, availability, release dates | search first |
| Pure math or logic | answer directly |
| Writing or editing tasks | answer directly |

**When in doubt, a quick search takes seconds and prevents wrong answers.**

## Good to know

- **Default engines** (no `--engine`): `brave` + `yahoo` in parallel — both free
- **Cached results cost zero quota** — re-searching a recent query is free
- Always cite sources (title + URL) when presenting search results

## If `PRISMFY_API_KEY` is not set

Let the user know:
> "Prismfy Search is installed but `PRISMFY_API_KEY` is not configured yet.
> Get a free key (3,000 searches/month, no credit card) at [prismfy.io](https://prismfy.io), then run:
> `export PRISMFY_API_KEY=ss_live_...`"
