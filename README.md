# homebrew-kenning

Homebrew tap for [Kenning](https://github.com/kenninglabs/homebrew-kenning) — a local-first
code-intelligence platform: a persistent code graph and knowledge index built from your own
repos, served entirely from your machine, plus a native MCP server so AI coding agents (Claude
Code, or any other MCP client) can search, explore, and recall real, evidence-backed context
instead of guessing or re-reading whole files.

## Why Kenning

Most AI coding assistants solve context the same way: upload your code (or embeddings of it) to
a server, or hand the model a huge pile of raw file contents and hope it finds the relevant part.
Both are expensive in tokens, slow to keep in sync as code changes, and — for the cloud options —
require trusting a third party with your source.

Kenning instead builds a **structural graph** of your codebase once (symbols, call edges, routes,
config keys) and keeps it current in the background. Retrieval then becomes a graph/index lookup
— no LLM call, no re-parsing, no upload — so an agent asking "who calls `OrderService`?" gets a
direct answer read off the graph instead of an LLM re-reading a dozen files to guess.

## Install

**Requires an Apple Silicon Mac** — the binaries are arm64 macOS only (no Intel or Linux builds
yet).

```sh
brew tap kenninglabs/kenning
brew install kenning              # CLI + daemon
brew install --cask kenning-ide   # Kenning.app (desktop IDE)
```

`Kenning.app` is signed but not yet notarized by Apple. If macOS refuses to open it, see
[Installing the desktop app](#installing-the-desktop-app) below.

## Quick start

```sh
kenning login                # one-time sign-in (GitHub or Google) — every other
                             # command refuses to run until you've done this

cd ~/my-project              # point Kenning at an existing project:
cat > .kenning.toml <<'EOF'
[hub]
name = "my-project"
[index]
repos = ["."]
EOF

kenning up                   # index everything, start the background daemon

kenning search "createOrder"                  # try it: symbol search
kenning ask "how does checkout emit events"   # or free-text retrieval

claude mcp add kenning -- kenning mcp         # give Claude Code the same powers
```

(For a multi-repo workspace, `kenning init` scaffolds the full hub layout instead — repos under
`source/`, a docs tree, agent-instruction shims. See [Hub setup](#hub-setup).)

From here the daemon watches your files and keeps the index current on its own; open
<http://127.0.0.1:8082> for the web UI.

## What you get

- **`kenning` CLI + daemon** — indexes your repos into a local code graph and serves
  search/explore/recall over it; a background watcher keeps the graph current as you edit.
- **`Kenning.app`** — a native desktop IDE built around the same index: code editor,
  interactive dependency graph, integrated git, and AI chat grounded in your own codebase.
- **MCP server** — `search_code`, `explore`, `recall`, `memory_store`, and more, exposed to
  Claude Code or any MCP-compatible agent, so agents retrieve evidence-backed context instead
  of re-reading whole files.
- **Broad language coverage** — Java, Go, Rust, Python, JS/TS, C/C++, Ruby, C#, Kotlin, Swift,
  and more, with framework-aware routing for Express, NestJS, React, Rails, Django, Laravel,
  and others.
- **Local-first by design** — one SQLite file per hub, served on `127.0.0.1` only. No cloud
  indexing and no telemetry by default. The one opt-in exception is signing in (GitHub/Google),
  used only to identify your account tier — it never uploads code.

## Hub setup

A **hub** is a directory holding one or more repos to index — every command operates on one.
`kenning up` (and most other commands) need a `.kenning.toml` at the hub's root before they'll do
anything; get there by hand-writing one, or by running `kenning init`.

Simplest form — index the current directory as a single repo:

```toml
[hub]
name = "my-hub"

[index]
repos = ["."]
```

Multi-repo form — everything under `source/` except one path you want to exclude, plus which
folders show up as editable docs on the desktop app's/web UI's knowledge tab:

```toml
[hub]
name = "my-hub"

[index]
repos = ["source/*"]          # glob of repo dirs, or list explicit paths
exclude = ["source/scratch"]  # optional — drop specific paths out of a glob match

[knowledge]                   # optional — defaults to knowledge/agentic/docs, whichever exist
dirs = ["knowledge", "docs"]
```

Repos you want `kenning init`/`kenning repo add` to clone for you, rather than checking out
yourself first, plus pinning one to a non-default branch:

```toml
[[repo]]
name = "payments-service"
url = "https://github.com/your-org/payments-service"

[branch]
"payments-service" = "develop"   # otherwise the remote's default branch is checked out
```

Two more optional tables exist for advanced setups — `[llm]` (which model tier/spend cap wiki
generation uses) and `[catalog]` (override the shared instruction/tool catalog's source repo).

**Where state lives** — entirely under `~/.kenning/`, never inside your repo:

| Path | What's there |
|---|---|
| `config.toml` | The registry of every hub you've set up on this machine, plus your signed-in identity. |
| `hubs/<hub-id>/kenning.db` | This hub's SQLite index — WAL mode, with versioned migrations that auto-upgrade an older hub's database (writing a backup first) rather than requiring a manual reset. |
| `hubs/<hub-id>/wiki/` | Generated wiki pages — regenerable, so they're kept out of your actual repo. |
| `logs/daemon.log` | Where `kenning up`'s detached daemon logs to (use `kenning serve` instead to watch it live in your terminal). |

## Command reference

What each command is for, and specifically what makes it fast — not just a flag list. Every
command below also accepts `--hub <path>` to target a hub other than the one auto-resolved from
your current directory (omit it and Kenning walks up from `.` to find one); most, but not all,
also accept `--json` for machine-readable output instead of the default text — noted per command
where it applies.

### Setup & account

See [Hub setup](#hub-setup) above for the `.kenning.toml` side of this. The commands below
manage a hub day to day:

| Command | What it's for | Where it's optimized |
|---|---|---|
| `kenning login` (or `kenning login github` / `kenning login google`) | One-time sign-in that unlocks the CLI/MCP/app — identifies your account tier. Omit the provider to be prompted. | GitHub uses OAuth Device Flow, Google uses a local-loopback redirect — neither requires Kenning to hold a server-side secret, since there's no backend to hold one on. |
| `kenning logout` | Clears the signed-in identity everywhere. | Signs the CLI **and** the desktop app out together, so you never end up with one half still "logged in." |
| `kenning init [--force]` | Scaffolds a multi-repo hub: `.kenning.toml`, local state, and (optionally) clones any repos declared in the config. Idempotent — re-running only fills in what's missing; `--force` re-runs even on a hub that's already fully set up. | Existing file content is never overwritten either way — `--force` only matters if nothing was left to fill in. |
| `kenning repo add <path-or-git-url> [--name <dir-name>]` | Register another repo into an existing hub, cloning it first if you passed a URL. `--name` picks the checkout directory (only used for a URL target; otherwise inferred from it). | Routes through the same code path the desktop app's "Add repo" button and the MCP `repo_add` tool use, so a repo added any of those three ways lands in the same place. |
| `kenning repo delete <name>` | Remove a repo's checkout from disk and untrack it from the hub. | — |
| `kenning up [--fresh-wiki]` | Indexes every repo in the hub, registers it, and starts the background daemon. `--fresh-wiki` also clears and regenerates every repo's wiki pages from scratch. | Batches each repo's writes into one transaction, hashes/reads files in parallel, and pipelines the cross-repo scan — cold index on a 30-repo/11k-file hub in **~21s** (down from ~40s pre-optimization). Re-running with nothing changed is a **~2.5s** no-op. |

If the daemon is already running, `repo add`/`repo delete` register on disk immediately but the
daemon itself only loads a hub's repo list at its own startup — restart it (`kenning serve`) or
run `kenning index --repo <name>` to pick up the change right away.

### Search & retrieval

| Command | What it's for | Where it's optimized |
|---|---|---|
| `kenning search <query> [--repo <name>] [--limit N]` | Find a symbol or string literal by name across the whole hub. `--limit` caps result count (default 20). | Backed by SQLite FTS5 — a text-index lookup, not a scan of every file. Supports `--json`. |
| `kenning explore <symbol> [--repo <name>] [--max-files N]` | See a symbol's neighborhood: callers, callees, and blast radius. `--max-files` caps how many files are shown (default 10). | Graph edges are precomputed at index time, so this is a graph traversal, not re-parsing anything — zero LLM cost. Supports `--json`. |
| `kenning ask <query> [--repo <name>] [--limit N]` | One call that runs both `recall` (docs/memory) and `search_code` (code) and returns two ranked sections. `--limit` (default 10) applies to each section. | Saves an agent the extra round-trip of guessing which of the two it needs and calling both separately. No `--json` output — text only. |
| `kenning recall <query> [--repo <name>] [--limit N]` | Full-text search over your docs, memories, and verified traces — not code. `--limit` defaults to 10. | Same FTS5 index as `search`, scoped to the knowledge substrate instead of the code graph. Supports `--json`. |
| `kenning status` | Per-repo index health, plus a running **tokens-saved** count. | Routes through the daemon over HTTP when it's running (so it never blocks on an in-progress index), and falls back to a direct DB read otherwise (SQLite WAL allows concurrent readers). Tokens-saved compares each retrieval's actual response size against the cost of the grep-then-open-the-file baseline it replaces. No `--json` — this one's terminal-output only. |

### Keeping the index current

| Command | What it's for | Where it's optimized |
|---|---|---|
| `kenning sync [--repo <name>]` | Force an incremental re-index — normally you don't need this, the daemon does it automatically on file save. | Only touches files that actually changed (adaptive debounce, 100ms/500ms under a burst of saves) instead of re-walking the whole repo — a no-op run completes in **under 2s** on a 30-repo hub. |
| `kenning sync --repo <name> --reset` | Wipe and rebuild one repo's graph from scratch. | Scoped to a single repo, so a bad/stale graph in one place doesn't force a full-hub reindex. |

### Knowledge substrate: memory, traces & wiki

Beyond the code graph, Kenning holds a second index over your team's *knowledge*: decisions,
verified facts, and an auto-generated wiki — this is what backs the "evidence-backed context"
claim above, not just marketing language.

| Command | What it's for | Where it's optimized |
|---|---|---|
| `kenning memory-store "<content>" --type <type> --tags <tags> [--repo <name>] [--scope <scope>] [--slug <slug>]` | Save a typed, tagged memory (a decision, a bug's root cause, a convention) — the same action the MCP `memory_store` tool performs on an agent's behalf. `--repo` records which repo it's really about (defaults to the cross-cutting `store` scope); `--scope` controls which `memory.md` file it's filed under (defaults to `--repo`'s value); `--slug` pins a stable identity, otherwise one's derived from tags/content on first save. | Upserts by (scope, slug): re-storing under the same identity updates it in place instead of duplicating, and it warns on near-duplicate content. Supports `--json`. |
| `kenning memory ingest [--repo <name>]` | Bulk-load `knowledge/<scope>/memory/memory.md` files into the searchable store (rows + full-text + embeddings). `--repo` scopes the run to just that one scope's file. | Idempotent — an unchanged section is skipped, so re-running after a small doc edit only touches what actually changed. Supports `--json`. |
| `kenning memory check [--repo <name>]` | Report-only: memories in the store with no backing file, or file sections not yet ingested. | Never writes anything — safe to run any time as a drift check. Supports `--json`. |
| `kenning trace-submit <trace.json>` | Submit a structured trace of how something was verified (which files were actually read, what was found). | **Fail-closed**: every read-hop in the trace must independently grep-verify against the real file before it's accepted and rendered — this is the mechanism, not just the claim, behind "evidence-backed." Supports `--json`. |
| `kenning wiki bootstrap <repo>` | Generate the initial wiki page skeleton for a repo, straight from its index. | No `--json` — this one's a scaffolding action, not a query. |
| `kenning wiki get <repo> [--slug <slug>]` | Fetch a wiki page, generating a skeleton first if it doesn't exist yet. | The wiki regenerates automatically from the index whenever the code changes — there's no propose/review queue to manage; these commands just scaffold and fetch. Supports `--json`. |

### Advanced / manual control

Most people never need these — `up` and the daemon's watcher already call into them automatically.

| Command | What it's for | Where it's optimized |
|---|---|---|
| `kenning index [--repo <name>] [--jobs N]` | The raw indexing step by itself, without registering the hub or starting the daemon — what `up` calls internally. | Parsing is parallelized across `--jobs` workers (default: all cores); useful in CI/scripts where you want an index without a long-running daemon process. Supports `--json`. |
| `kenning serve --port 8082` | The same daemon `up` starts, run in the foreground attached to your terminal instead of detached. | For debugging — you see daemon logs directly instead of tailing `~/.kenning/logs/daemon.log`. |
| `kenning audit [--strict] [--quiet]` | Hub hygiene lint (naming, dangling links, staleness) over hubs that use Kenning's own `knowledge/` doc convention. | `--quiet` for a one-line summary, `--strict` to fail on warnings too (default: fails only on errors) — built to be a CI gate. No `--json`. |
| `kenning migrate [--memory-db <path>] [--knowledge <dir>] [--skip-mcp] [--yes]` | One-time import for teams moving from `mcp-memory-service`, or bringing a hub's existing `knowledge/` docs into Kenning's store for the first time. `--knowledge` overrides which docs folder to read (default: `knowledge/` at the hub root); `--skip-mcp` imports docs only, skipping the mcp-memory-service DB. | Safe by default — without `--yes` it only prints a plan (doc/memory counts) and writes nothing; `--yes` is what actually applies it. Supports `--json`. |
| `kenning migrate --rewrite-mirrors --yes` | A separate, standalone maintenance action: rewrites every memory's markdown mirror file to the current naming convention, deleting the superseded one. | Skips the normal import path entirely — always requires `--yes` (no preview mode for this one). |

### MCP, for Claude Code or any MCP client

```sh
claude mcp add kenning -- kenning mcp
# or, against the running daemon:
claude mcp add --transport http kenning http://127.0.0.1:8082/mcp
```

| Form | What it's for | Where it's optimized |
|---|---|---|
| `kenning mcp` (stdio) | One process per agent connection, talking JSON-RPC over stdio. | No network hop — the agent host spawns it directly as a child process, the transport Claude Code uses by default. |
| Daemon `/mcp` (HTTP) | Share one always-on MCP endpoint across multiple agent connections. | The daemon already holds the warm index in memory/WAL cache, so a new connection doesn't pay the cold-start cost `kenning mcp` would. |

**Tool availability differs by transport** — `kenning mcp` (stdio) exposes 19 tools; the daemon's
`/mcp` (HTTP) exposes 16, since three tools that write to the knowledge substrate are stdio-only
(see below). Both share the same base set:

- **Retrieval, on both transports** — `search_code`, `explore`, `ask`, `status`, `sync`,
  `staleness`
- **Repo & hub management, on both transports** — `recall`, `repo_add`, `repo_delete`,
  `instructions_get`/`instructions_toggle_system`/`instructions_save_user`/
  `instructions_delete_user`, `tools_list`/`tools_save_user`/`tools_delete_user`. Since one
  daemon serves every registered hub at once, most of these accept a `hub_id` on the daemon to
  say which hub to act on — required for `repo_add`/`repo_delete`, optional (defaulting to the
  first registered hub) for the `instructions_*`/`tools_*` ones, and irrelevant for `recall`
  (it searches across every loaded hub regardless). Over stdio, `kenning mcp` is already scoped
  to the one hub it was started in, so none of this applies there.
- **Knowledge substrate (memory, traces, wiki), stdio only** — `memory_store`, `trace_submit`,
  `wiki_get`. The daemon's HTTP `/mcp` doesn't declare these at all (not broken — genuinely not
  offered there). If an agent needs to save a memory, submit a trace, or fetch a wiki page, it
  needs the stdio form.

**Client-capability tiering.** A caller can identify itself as a small/local model and get a
reduced tool list of just `ask` + `explore` on either transport — deliberately, because a small
model can't reliably pick the right tool out of several similarly-named, overlapping ones (`ask`
vs `search_code` vs `explore` vs `recall`), and `ask` alone already fuses the two most useful
calls into one. Opt in with `clientInfo.name: "kenning-local-tier"` in your `initialize` call
(stdio), or an `X-Kenning-Tool-Tier: local` header (HTTP). This is a discoverability aid, not a
security boundary — any caller can claim either identity.

**One prompt, stdio only.** `kenning mcp` also serves a `trace-methodology` prompt (via
`prompts/list`/`prompts/get`) — a structured, evidence-gated methodology for tracing a code flow
hop-by-hop before writing anything to the knowledge store. The daemon's HTTP `/mcp` route has no
`prompts` handling at all; use the stdio form if you want this.

Full command reference: `kenning --help` / `kenning <command> --help`.

## The web UI

While the daemon runs, <http://127.0.0.1:8082> serves a browser UI over the same index —
server-rendered, localhost-only, no login page and no JavaScript framework:

- `/system` — daemon health: per-repo node/edge counts, live progress bars while a repo
  (re)indexes, and per-repo reset buttons
- `/search` — the same symbol/literal search as `kenning search`, as a form
- `/memory` — browse stored memories, filterable by text and tag
- `/wiki` — the auto-generated, evidence-gated wiki for each repo
- `/graph` — an interactive WebGL graph of a repo's symbols: hover to highlight a symbol's
  neighborhood, click for details, `/` to search within the graph

## Performance (measured)

Measured on a 30-repo, ~11,300-file hub, Apple M2 (8 cores, 24 GB). Your numbers will vary with
repo size and hardware — these are here to show *where* the design puts its effort, not as a
universal benchmark.

| Operation | Measured | Why |
|---|---|---|
| Cold index, whole hub | ~21s | Batched per-repo transactions + parallel file read/hash + pipelined cross-repo writes. |
| Re-`up` with nothing changed | ~2.5s | Skips everything already indexed; only re-checks freshness. |
| No-op incremental sync | ~1.8s | Watcher already knows nothing changed — no re-parse. |
| Single file save → queryable | ~200-350ms steady-state | Debounced watcher re-parses just that file and updates the index in place. |
| Daemon idle memory | ~24 MB RSS | The daemon is meant to run continuously in the background without being a resource cost you notice. |

## Plans

| | Free | Team | Enterprise |
|---|---|---|---|
| Repos per hub | 25 | 50 | Unlimited |
| Hubs | 1 | 1 | Unlimited, dedicated infra |
| Connected agents/IDEs | 1 agent + 1 IDE | Multiple, up to 20 users | Multiple, 20+ users |
| Shared wiki, team token-savings rollup, synced agent policy | — | Included | + audit export |
| Auth | GitHub / Google | GitHub / Google | + SSO/SAML |
| Support | Community (GitHub issues) | Priority, 1-business-day ack | SLA-backed, named contact |

Free requires nothing but signing in. **Team and Enterprise are not yet purchasable** — open
an issue on this repo if you want early access.

## How Kenning compares

Kenning's specific niche is a **persistent, local code graph with a background daemon, a native
MCP server, and a desktop IDE, all in one binary set**. Here's how nearby tools differ, based on
their own public docs — accurate as of this writing; these products all ship fast, so verify
current behavior yourself before it factors into a decision.

| Tool | Where the index lives | Persistent graph on disk | MCP server | Desktop IDE |
|---|---|---|---|---|
| **Kenning** | 100% local (SQLite, `127.0.0.1` only) | Yes — a daemon keeps it current | Yes, native | Yes (`Kenning.app`) |
| [Sourcegraph Cody](https://sourcegraph.com) | Sourcegraph's own instance (cloud, or self-hosted at Enterprise cost) | Only if you run self-hosted Sourcegraph | Limited | No (editor extension) |
| [Cursor](https://cursor.com) | Plaintext stays local; code chunks are uploaded to compute embeddings, stored in Cursor's cloud vector store | No | No | Yes (full editor) |
| [GitHub Copilot](https://github.com/features/copilot) | Remote index built on GitHub's servers (non-GitHub/local repos are uploaded to build one) | No | No | No (editor extension) |
| [Aider](https://aider.chat)'s repo map | 100% local | No — rebuilt from tags/tree-sitter each run | No | No (terminal tool) |
| [Serena](https://github.com/oraios/serena) | 100% local, via LSP | Per-file symbol cache on disk, not a cross-repo relational graph | Yes, MCP-native | No |

Aider's repo map and Serena are the closest fully local, MCP-friendly peers. Neither runs a
background daemon that watches your files and keeps an index current on its own — Aider
recomputes its repo map each run, and Serena's on-disk cache is a per-file LSP symbol cache
rather than a relational graph of cross-file call/route edges. Neither ships a web UI, wiki, or
desktop app. Cursor, Copilot, and Cody are effective at what they do, but all involve your code
touching a server in some form — as embeddings, a remote index, or both — to work across a large
codebase.

## Installing the desktop app

Kenning.app is ad-hoc signed but not notarized by Apple, so macOS will block it on first
launch. Easiest fix — install without the quarantine flag in the first place:

```sh
brew install --cask --no-quarantine kenning-ide
```

Already installed and blocked?

```sh
xattr -dr com.apple.quarantine /Applications/Kenning.app
```

Or allow it once via System Settings → Privacy & Security → "Open Anyway". The `kenning`
CLI is unaffected either way.

## What lives here

This repo contains **only** packaging files and compiled release assets:

- `Formula/kenning.rb` — the CLI/daemon binary
- `Casks/kenning-ide.rb` — the desktop app
- GitHub Releases — the binaries themselves

Kenning is proprietary and its source is not published. Nothing in this repo
is source code, and nothing here is hand-edited: both `.rb` files are
generated by `packaging/release.sh` in the private product repo, which
computes the checksums during the build and writes the final formula and cask
directly. Editing them by hand will be overwritten on the next release.
