# OSS Status -- jluocsa

Auto-refreshed daily by [refresh-oss-status.ps1](./refresh-oss-status.ps1).
Hand-curated sections (queue, notes) live outside the marker blocks and are
preserved across runs.

**Last refreshed:** 2026-09-04 16:54

## Open PRs

<!-- BEGIN: PR_TABLE -->
| # | Repo | Title | Mergeable | MergeState | Checks | Reviews | Age |
|---|---|---|---|---|---|---|---|
| [#59](https://github.com/DanGiannone1/csa-workbench/pull/59) | DanGiannone1/csa-workbench | examples: add a runnable Agent Framework evaluation lane | MERGEABLE | BLOCKED | none reported | none | 23d |
| [#3069](https://github.com/Azure-Samples/azure-search-openai-demo/pull/3069) | Azure-Samples/azure-search-openai-demo | Heal LLM-simplified citations to canonical reference | MERGEABLE | CLEAN | 1✅ | none | 97d |
| [#3068](https://github.com/Azure-Samples/azure-search-openai-demo/pull/3068) | Azure-Samples/azure-search-openai-demo | Add current date to query rewrite and chat answer prompts | CONFLICTING | DIRTY | 1✅ | pamelafox:CHANGES_REQUESTED | 97d |
| [#6054](https://github.com/microsoft/agent-framework/pull/6054) | microsoft/agent-framework | samples: add McpDocsResearch declarative workflow showcasing agent-level MCP pattern | UNKNOWN | UNKNOWN | 1 skipped, 1✅ | copilot-pull-request-reviewer:COMMENTED | 104d |
| [#5908](https://github.com/microsoft/agent-framework/pull/5908) | microsoft/agent-framework | .NET: fix(aspire-devui): ship Microsoft.Agents.AI.DevUI as a transitive dependency | UNKNOWN | UNKNOWN | 1 skipped, 1✅ | copilot-pull-request-reviewer:COMMENTED | 110d |
| [#5907](https://github.com/microsoft/agent-framework/pull/5907) | microsoft/agent-framework | .NET: docs(aspire-devui): align README usage example with WithAgentService semantics | UNKNOWN | UNKNOWN | 1 skipped, 1✅ | copilot-pull-request-reviewer:COMMENTED | 110d |
| [#2704](https://github.com/openai/openai-cookbook/pull/2704) | openai/openai-cookbook | Add maxreid-openai to authors.yaml (5 referenced pages) | MERGEABLE | BLOCKED | none reported | none | 110d |
| [#2702](https://github.com/openai/openai-cookbook/pull/2702) | openai/openai-cookbook | Add alfozan to authors.yaml (referenced by #2658) | MERGEABLE | BLOCKED | none reported | none | 110d |
| [#2443](https://github.com/github/github-mcp-server/pull/2443) | github/github-mcp-server | warn that issue_write body REPLACES content, not appends (fixes #2410) | CONFLICTING | DIRTY | none reported | copilot-pull-request-reviewer:COMMENTED, pachecocordovamoiseseduardo-byte:APPROVED, jluocsa:COMMENTED, jluocsa:COMMENTED, pachecocordovamoiseseduardo-byte:APPROVED | 120d |
| [#2669](https://github.com/openai/openai-cookbook/pull/2669) | openai/openai-cookbook | docs: fix typos across example notebooks | CONFLICTING | DIRTY | none reported | none | 120d |
<!-- END: PR_TABLE -->

## Recently merged (last 30 days)

<!-- BEGIN: MERGED_TABLE -->
| # | Repo | Title | Merged |
|---|---|---|---|
| [#6046](https://github.com/microsoft/agent-framework/pull/6046) | microsoft/agent-framework | .NET: docs(decisions): resolve duplicate ADR sequence numbers (0016, 0021, 0024) | 2026-08-31 |
<!-- END: MERGED_TABLE -->

## Queue / Priorities

_Triaged 2026-08-29 against freshly fetched upstreams._

### 1. DONE - closed 2026-08-29

- **semantic-kernel #14031** (Scriban 7.1.0 -> 7.2.0) - **CLOSED as superseded**.
  Commit `33a3e555e` (".Net: [BREAKING] Upgrade Prompty.Core to 2.0.0-beta.3 to
  resolve NU1903 vulnerability", PR #14169, merged 2026-07-20) fixed the same
  NU1903/GHSA-24c8-4792-22hx advisory by removing the vulnerable transitive dependency.
  Scriban is now absent from all of `dotnet/`, so merging would have re-added a
  `PackageVersion` entry for an unused package. Closed with a pointer to #14169.
- **openai-cookbook #2738** (Foundry evaluators outline) - **CLOSED**. Draft for 98d with
  zero maintainer reviews; carried the `Stale` label and was queued for bot auto-closure.
  Closed cleanly; branch retained so it can be reopened as a complete notebook.

### 2. Blocked on maintainer action only (nudge, don't code)
- **agent-framework #5907, #5908, #6054** - MERGEABLE, checks green, still merge cleanly
  onto current `upstream/main`. Only awaiting maintainer review/merge.
- **azure-search-openai-demo #3069** - MERGEABLE/CLEAN, checks green, no reviewer assigned
  in 91d. Merges cleanly. Request a reviewer.
- **csa-workbench #59** - BLOCKED, no reviews in 17d. Request a reviewer.

### 3. Needs real work before it can merge

- **azure-search-openai-demo #3068** (current date in prompts) - CONFLICTING plus
  `pamelafox: CHANGES_REQUESTED`. All 9 conflicts are regenerated `tests/snapshots/**`
  `result.jsonlines` files: rebase, then regenerate snapshots rather than hand-merging.
- **github-mcp-server #2443** (issue_write body REPLACES) - 201 commits behind upstream.
  Conflicts in `README.md`, `docs/feature-flags.md`, `docs/insiders-features.md`,
  `pkg/github/issues.go`, plus a modify/delete on
  `__toolsnaps__/issue_write_ff_remote_mcp_issue_fields.snap` (deleted upstream).
  Already has 2 approvals - worth rebasing promptly before it rots further.
- **openai-cookbook #2669** (typo fixes) - 62 behind; conflicts in 3 notebooks.
  **Partially obsolete**: `occurences`, `funtionality` and `Recieve` have since been fixed
  upstream, but `OpeanAI`, `seperate`/`seperately` and "They needs" are still present.
  Rebase and keep only the still-valid hunks - do not close.

### 4. DONE - pushed 2026-08-29 (all three now MERGEABLE)

- **agent-framework #6046** (duplicate ADR numbers) - **the original PR would have made
  things worse.** It renumbered `0016->0027`, `0021->0028`, `0024->0029`, but upstream has
  since taken all three (`0027-hosting-channels.md`,
  `0028-hosting-linking-multicast-enhancements.md`, and *two* `0029-*` files), so merging
  would have produced 0027 x2, 0028 x2 and 0029 x4. Git still reported a "clean" merge
  because renames to new filenames never conflict textually.
  Rebuilt on current `upstream/main` using the free slots **0036 / 0037 / 0038**
  (highest in use upstream is 0035). Verified: renames are content-free, all 6
  cross-references updated across 4 files, **0 dead links**, and the 3 originally
  targeted duplicates are gone. **Pushed**; a comment on the PR explains the
  renumbering so reviewers aren't surprised by the changed target numbers.
  Note: 3 duplicate pairs remain upstream (**0029, 0032, 0035**) that were never in this
  PR's scope - worth a follow-up issue.
- **openai-cookbook #2702** (`add-alfozan-author`) and **#2704** (`add-maxreid-openai-author`)
  were pure end-of-file append conflicts in `authors.yaml`. Both rebased onto current
  `upstream/main`, YAML validated (128 -> 129 entries, no upstream entries lost), and
  **pushed**. Neither author existed upstream, so both PRs were still needed.

All three flipped CONFLICTING -> MERGEABLE after the push.

### Housekeeping

- **github-mcp-server** working tree had 106 modified `__toolsnaps__/*.snap` files that
  differed **only by line endings** (`core.autocrlf=true`, repo has no `.gitattributes`).
  **Reverted** on 2026-08-29 after confirming `git diff --ignore-cr-at-eol` was empty;
  tree is now clean. Expect this to recur on Windows - consider adding a `.gitattributes`.
  A stash remains: `WIP: issue-2410 body description (auto-stashed for #2483 work)`.
- **refresh-oss-status.ps1 encoding bug - FIXED.** The script is UTF-8 and contains literal
  non-ASCII characters (U+2705 check, U+274C cross, U+2014 em-dash), but had no BOM.
  Windows PowerShell 5.1 parses BOM-less `.ps1` files as CP1252, so those literals were
  mangled at *parse* time and re-encoded as UTF-8 on write - corrupting the file a little
  more on every single run (this is where the pre-existing mojibake in this file came
  from). Fixed by adding a UTF-8 BOM to the script and switching its file I/O to explicit
  `UTF8Encoding($false)`. Verified stable across repeated runs.
