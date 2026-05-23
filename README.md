# oss-status-tracker

A tiny daily refresher for an `OSS-STATUS.md` file that surfaces a single GitHub
user's open PRs and recent merges across **every** repo they contribute to. Drop
it into a repo, set one secret, and the file refreshes itself on a cron — your
hand-curated queue and notes are preserved byte-for-byte across runs.

Built as a dual-mode reference:

- **Deterministic mode (today)** — `refresh-oss-status.ps1` runs against `gh`
  CLI. No LLM dependency, no API keys beyond a GitHub token. This is what the
  GitHub Action actually executes.
- **Agent mode (dogfood)** — `agent-workflow/oss-status-tracker.yaml` is the
  same pipeline expressed as a [Microsoft Agent Framework][maf] declarative
  workflow with a **WatcherAgent** (MCP-backed) and **TrackerAgent**
  (file-editing). Provided so you can A/B the two implementations and run the
  agent version when you want richer signals (stale-thread detection,
  Q&A-answerability scoring, CODEOWNER nudges) that a deterministic script
  can't easily do.

[maf]: https://github.com/microsoft/agent-framework

## What you get

```text
## Open PRs
| #     | Repo                     | Title                            | Mergeable | MergeState | Checks | Reviews | Age |
| #2738 | openai/openai-cookbook   | Add agent regression tests …     | MERGEABLE | BEHIND     | 12✅   | none    | 1d  |
| #6054 | microsoft/agent-framework| samples: add McpDocsResearch …   | MERGEABLE | BLOCKED    | 0 expected | none | 0d |

## Recently merged (last 30 days)
| #     | Repo                     | Title                            | Merged     |
| #2704 | openai/openai-cookbook   | authors.yaml: add maxreid-openai | 2026-05-18 |
```

Your queue, escalation calendar, and notes live outside the marker blocks and
are preserved on every run.

## Quick start

```bash
gh repo create <you>/oss-status-tracker --public --template jluocsa/oss-status-tracker
cd oss-status-tracker
# Optional: pre-create OSS-STATUS.md with your queue.
# Run locally:
pwsh ./refresh-oss-status.ps1 -User <you>
```

The first run creates `OSS-STATUS.md` from a template if missing. After the
first commit, the daily Action (13:30 UTC) keeps it fresh.

## Configuration

| Knob                     | How to set                                       | Default                          |
| ------------------------ | ------------------------------------------------ | -------------------------------- |
| GitHub user to track     | Repo variable `OSS_TRACKER_USER` _or_ env var    | `github.repository_owner`        |
| Repos to exclude         | Repo variable `OSS_TRACKER_IGNORE_REPOS` (csv)   | _(none)_                         |
| Token used by `gh`       | Repo secret `OSS_TRACKER_PAT` (optional)         | `GITHUB_TOKEN` (public data only)|
| Merged-window (days)     | `-MergedDays N` flag                             | `30`                             |
| Skip repos (CLI)         | `-IgnoreRepos repo1,repo2` flag                  | _(none)_                         |

When `OSS_TRACKER_PAT` is **not** set the action uses the default
`GITHUB_TOKEN`, which can read public PR/issue/discussion data across all
public repos — fine for a public OSS tracker. Set a PAT only if you need
access to private repos or org-scoped data behind SSO.

## Files

```
.
├─ refresh-oss-status.ps1                  Deterministic refresher (the cron runs this).
├─ .github/workflows/refresh.yml           Daily cron + manual dispatch.
├─ agent-workflow/
│  ├─ oss-status-tracker.yaml              Microsoft Agent Framework workflow.
│  └─ agents/
│     ├─ WatcherAgent.yaml                 MCP-backed Prompt agent.
│     └─ TrackerAgent.yaml                 File-rewriting Prompt agent.
└─ OSS-STATUS.md                           The artifact this repo refreshes.
```

## How agent mode works (when you opt in)

The workflow is a two-step sequential pipeline:

1. **WatcherAgent** receives the GitHub login as input and uses GitHub MCP
   tools (`search_pull_requests`, `pull_request_get`, `list_pull_requests`,
   `search_issues`) to produce a strict JSON delta:

   ```jsonc
   {
     "openPrs":   [ { "number": 6054, "repo": "microsoft/agent-framework", "title": "…",
                      "url": "…", "mergeable": "MERGEABLE", "mergeState": "BLOCKED",
                      "checks": { "success": 0, "failure": 0, "pending": 0 },
                      "reviews": "none", "ageDays": 0 } ],
     "mergedPrs": [ { "number": 2704, "repo": "openai/openai-cookbook", "title": "…",
                      "url": "…", "mergedAt": "2026-05-18" } ]
   }
   ```

2. **TrackerAgent** receives the delta and the current `OSS-STATUS.md`, then
   rewrites only:
   - the `<!-- BEGIN: PR_TABLE -->` / `<!-- END: PR_TABLE -->` block
   - the `<!-- BEGIN: MERGED_TABLE -->` / `<!-- END: MERGED_TABLE -->` block
   - the `**Last refreshed:** …` line

   Every other line is preserved byte-for-byte. The agent is run at
   `temperature: 0.0` and is forbidden from emitting chat.

To execute the agent workflow today you need an Agent Framework host (.NET or
Python) that registers the two agents and loads `oss-status-tracker.yaml`.
That host is not yet in this repo — see the `agent-workflow/` directory for
the YAMLs and the [Marketing.yaml sample][marketing] in the framework repo for
the host pattern.

[marketing]: https://github.com/microsoft/agent-framework/blob/main/declarative-agents/workflow-samples/Marketing.yaml

## Why dual-mode?

The deterministic script is **what you want on cron**: no API key, no
non-determinism, fast, observable. The agent workflow is **what you want when
extending**: adding stale-thread detection, Q&A-answerability scoring, or
CODEOWNER-aware nudges is a one-prompt edit instead of a hundred lines of new
PowerShell. They share the same artifact contract (`OSS-STATUS.md` marker
blocks), so you can swap implementations without rewriting consumers.

## License

[MIT](./LICENSE)
