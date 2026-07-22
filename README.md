# vci

<!-- badges: start -->
<!-- badges: end -->

**Status: pre-alpha — specification stage. There is no package code yet.**

`vci` will be an R package that converts spatially varying vector biology,
environment, human behaviour, and intervention scenarios into vectorial capacity
and **vector control impact** (VCI): the proportional reduction in vectorial
capacity attributable to a set of interventions.

It is being developed as part of [Vector Atlas
II](https://vectoratlas.icipe.org/) (Intermediate Outputs 1.1.1–1.1.3), and is
intended to sit between entomological data and maps, mechanistic malaria
transmission models, and geospatial burden models. It computes vector-side
transmission potential and its response to control; it does **not** simulate
malaria transmission or predict cases, deaths, or optimal intervention
allocation.

## What it will do

- Species-specific vectorial capacity in the Garrett-Jones form, and aggregation
  across species.
- Baseline and intervention scenarios, with VCI expressed against a named
  reference scenario.
- Modular, registered component models (host encounter, adult survival, larval
  habitat, parasite development, intervention effects, …) selected by versioned,
  inspectable presets — starting with `va_v1`.
- Pixel and administrative-area workflows, via `sf`/`terra` adapters over a
  non-spatial computational kernel.
- Uncertainty propagation by draw or ensemble.
- Provenance on every result: equations, assumptions, component versions,
  parameter sources, units, and input checksums.

See [`DESIGN.md`](DESIGN.md) for the full design specification and
[`MATHEMATICAL_SPEC_WORKING.md`](MATHEMATICAL_SPEC_WORKING.md) for the current
working version of the mathematical framework.

## Installation

Not yet installable. When there is a package to install, it will be available
with:

``` r
# install.packages("remotes")
remotes::install_github("idem-lab/vci")
```

## Repository contents

| Path | What it is |
| --- | --- |
| [`DESIGN.md`](DESIGN.md) | Draft design specification (v0.1): scope, architecture, data contracts, API sketch, delivery plan, open decisions. |
| [`MATHEMATICAL_SPEC_WORKING.md`](MATHEMATICAL_SPEC_WORKING.md) | Working mathematical specification for the base (Vector Atlas v1) framework — confirmed decisions and explicitly labelled open items. |
| [`CLAUDE.md`](CLAUDE.md) | Instructions loaded by Claude Code at the start of every session: how humans and AI agents are expected to work together on this project. |
| `.claude/hooks/log-session.sh` | Stop hook that writes a readable log of each Claude Code session into `dev/sessions/`. |
| `dev/sessions/` | Auto-generated session logs (git-tracked, excluded from the built package). |

## The role of AI in this package

AI coding assistants are used substantially in the development of this package.
We think that is defensible only if it is *legible* — so the provenance of every
part of this repository is recorded, and every AI-assisted change ships with the
prompts that produced it. This section is that record. Please read it as part of
evaluating the package.

The scientific content is human-owned throughout. Equations, assumptions, and
their sign-off are the responsibility of the human maintainers; AI agents do not
change scientific assumptions without a human-reviewed decision record.

### Provenance of the current documents

- **`CLAUDE.md`** and **`.claude/hooks/log-session.sh`** (plus
  `.claude/settings.json`) were written by **Claude chat (Opus 4.8)** before
  development of this repository began, and then hand-edited by Nick Golding.
- **`DESIGN.md`** was automatically constructed from a prompt written by Nick
  Golding, based on source documents he provided. The sources are listed in
  §18 "Source traceability" at the bottom of that document. It is a draft: where
  the sources were ambiguous it deliberately records an open decision rather than
  asserting a final answer.
- **`MATHEMATICAL_SPEC_WORKING.md`** was compiled by **Microsoft Copilot
  (GPT-5.6)** from equations written by Nick Golding. Copilot contributed minor
  corrections and suggested edits, and constructed the basic and detailed
  notation. The mathematics is Nick's; the transcription, notation, and prose
  are AI-assisted and under human review.
- **This README** was drafted by Claude Code (Opus 4.8) from the documents above,
  to a specification given by Nick Golding, and edited by him.

### Provenance of package code, from here on

All package development is done with local Claude Code agents (there is no
`@claude` GitHub Actions automation), under a workflow designed to keep the AI
contribution reviewable:

1. **Every session is logged.** A Stop hook writes the user prompts and Claude's
   text responses for each session to `dev/sessions/<date>-<session-id>.md`, and
   that log is committed with the change. The prompts that produced a diff travel
   with the diff.
2. **Every pull request explains how it was produced.** PR descriptions carry a
   "How this was produced" section giving the issue, the core prompts, the key
   decisions or trade-offs the agent made or asked about, any new dependencies
   and why, and a link to the session log.
3. **Every pull request is reviewed by a human**, including each maintainer's own
   agent-generated PRs. Nothing is pushed to `main` directly.
4. **Work is test-first.** Behaviour is specified by a failing `testthat` test
   before it is implemented, so the tests — not the agent's narrative — are what
   the review checks against.

The full conventions are in [`CLAUDE.md`](CLAUDE.md). If you find something in
this package that looks like a plausible-sounding error of the kind these
assistants produce, please open an issue — the session logs should make it
possible to see exactly how it got there.

## Contributing

Development is public and contributions are welcome, but note that the package
is at specification stage: the most useful contribution right now is scientific
review of [`DESIGN.md`](DESIGN.md) and
[`MATHEMATICAL_SPEC_WORKING.md`](MATHEMATICAL_SPEC_WORKING.md), particularly the
open items each of them lists. Please raise these as issues.

Contributors who use AI assistance are asked to follow the same transparency
conventions described above.

## Licence

MIT © Nick Golding. Further contributors will be added to the licence as the
package develops.
