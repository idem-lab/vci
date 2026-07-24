# Vectorial Capacity and Vector Control Impact R Package

**Status:** Draft design specification v0.1  
**Audience:** Human developers, AI coding agents, scientific reviewers, downstream modellers  
**Project:** Vector Atlas II, Intermediate Outputs 1.1.1–1.1.3  
**Last updated:** 2026-07-22

## 1. Purpose

Develop an open-source, versioned R package that converts spatially varying vector biology, environment, human behaviour, and intervention scenarios into:

1. baseline vectorial parameters;
2. baseline and scenario-specific vectorial capacity;
3. vector control impact (VCI), expressed primarily as proportional or percentage reduction in vectorial capacity;
4. model-specific parameter products compatible with malaria epidemiological and mechanistic modelling workflows.

The package is intended to bridge entomological data and maps, mechanistic malaria models, geospatial burden models, and interpretable decision-support outputs. It supports, but does not replace, models of downstream cases, deaths, cost-effectiveness, or intervention allocation.

### 1.1 The package in plain terms

The rest of this document is written for implementers. In outline, the package is a calculator with swappable parts:

- **The parts.** Each biological step — how much larval habitat exists, how many adult mosquitoes that supports, how long they live, when and where they bite, what a bed net does to them — is a separate model with declared inputs and outputs. There can be several competing implementations of any step (§6).
- **The recipe.** A *preset* is a named, versioned list of which implementation to use for each step. `va_v1` is the first. A recipe can be inspected before it is run, and a part can be swapped — but the result is then labelled a modified recipe, not the original (§6.2, §6.3).
- **The calculator.** The engine runs the chosen parts in order to produce vectorial capacity: a number per place, per time, per species. It has two halves. The first — climate, habitat, mosquito population, abundance — does not depend on which interventions are deployed, so it runs once. The second — biting, nets and spraying, survival, capacity — runs once per scenario on top of it (§6.0).
- **The comparison.** Compute capacity for the world as it is and for the world with a proposed intervention; the drop between them is the vector control impact (§5.3).
- **The paperwork.** Every result records which parts, which versions, which data and which assumptions produced it, so any number can be traced back (§9).
- **The maps.** The calculator itself knows nothing about geography. It works on arrays of numbers indexed by place. Separate adapters turn rasters or district boundaries into those arrays and turn the answers back into maps (§7.1, §7.1.1).

Two workloads are representative, and both use the same array structures (§7.1.1):

- a single deterministic calculation across districts for two scenarios, which is the common case and should complete in seconds once district-level parameters are prepared;
- a multi-draw calculation at pixel level, which is among the most computationally demanding uses of the framework.

## 2. Product principles

- **Scientifically explicit:** every result records equations, assumptions, component implementations, parameter sources, units, and versions.
- **Modular:** users can select individual component models or named presets reproducing a coherent published implementation.
- **Safe by default:** validates units, ranges, dimensions, spatial alignment, missingness, and incompatible component combinations.
- **Reproducible:** deterministic calculations are stable; stochastic calculations accept seeds and preserve provenance.
- **Spatial but not spatially captive:** core calculations operate on typed tabular/array inputs; adapters support `sf`, `terra`, and administrative-area tables.
- **Uncertainty-aware:** supports draws or ensembles and propagates uncertainty through derived quantities.
- **Accessible:** high-level workflows for analysts, lower-level component APIs for modellers, and a stable engine suitable for dashboard integration.
- **Open and extensible:** public development, permissive open-source licensing subject to project approval, FAIR-aligned outputs, contributor documentation, and stable extension interfaces.
- **Idiomatic and minimal:** the implementation stays as small and as conventional for R users and developers as the design allows. Prefer the mechanisms an R package already provides (function documentation, signatures, `NAMESPACE`, lifecycle badges) over bespoke machinery, and prefer functions from well-established, well-maintained packages — `sf` and `terra` for spatial data in particular — over re-implementing them, unless there is a specific reason (performance, stability, licensing) to do otherwise. This is a design constraint, not only a coding-style preference: it bounds what the package builds. See the dependency policy in `CLAUDE.md`; surface any borderline dependency decision to a human.

## 3. Users and primary jobs

Initial user archetypes will be developed separately. The design must at least support:

1. **National/TSU spatial analyst:** provide intervention coverage by raster or administrative area and produce VCI maps with documented defaults.
2. **Vector scientist:** inspect and substitute vector biology layers or parameter relationships and diagnose biological plausibility.
3. **Mechanistic malaria modeller:** request parameter layers and presets aligned with OpenMalaria, malariasimulation, EMOD, and potentially VCOM.
4. **MAP/geospatial modeller:** generate harmonised space-time cubes and uncertainty summaries for national or Africa-wide models.
5. **Package developer/model contributor:** add a component implementation without modifying the orchestration engine.
6. **Dashboard integrator:** call a small, stable, serialisable API without requiring interactive R knowledge from end users.

## 4. Scope

### 4.1 Version 1 target

- Species-specific vectorial capacity using the Garrett-Jones form.
- Multiple-species aggregation.
- Baseline and intervention scenarios.
- Attempted and successful human biting, adult survival, population dynamics, larval habitat, parasite development and infection, host encounter, human availability, and intervention-effect components (the full set and their execution stages are in §6.1).
- Intervention effects resolved into the repellency/accessibility, barrier, and killing channels (`R`, `B`, `Kᵉ`).
- Multiple species handled as a modelling dimension (per-species capacity, summed; §5.2).
- Larval source management effects.
- Named intervention types sufficient for prototype LLIN/net types and IRS analyses, with explicit resistance modifiers.
- Pixel and administrative-area workflows.
- User replacement of default layers and component models.
- Uncertainty propagation by draw/ensemble.
- Named implementation presets, initially `va_v1`; placeholders and interfaces for model-aligned presets.
- Export of maps, tables, diagnostics, provenance, and machine-readable manifests.

### 4.2 Future scope

- Faithful, tested representations of relevant vectorial-capacity components in OpenMalaria, malariasimulation, EMOD, and possibly VCOM.
- Hybrid user-composed models, subject to compatibility checks.
- Emerging controls such as ATSB and population suppression/replacement gene-drive payloads.
- Within-species seasonal behavioural variation and optional vector competence.
- Dashboard adapters or a lightweight local Shiny interface if partner integrations do not meet user needs.

### 4.3 Non-goals

- Full malaria transmission simulation.
- Direct prediction of cases, deaths, DALYs, budgets, or optimal allocation.
- Fitting all underlying geostatistical surfaces inside the package.
- Silent conversion between incompatible assumptions or units.

## 5. Scientific model

### 5.1 Core quantity

For species `s`, location `i`, and time `t`:

```math
V_{s,i,t} = \frac{m_{s,i,t} a_{s,i,t}^{2} p_{s,i,t}^{v_{s,i,t}}}{-\log(p_{s,i,t})}.
```

with

```math
m_{s,i,t}=M_{s,i,t}/H_{i,t}, \qquad M_{s,i,t}=\bar n_{s,i,t}L_{s,i,t}.
```

Here `H` is human population or density, `L` is maximum effective larval habitat, and `n_bar` is average adult mosquitoes per unit larval habitat, described through a dynamic aquatic/adult-stage model.

**The maths spec is authoritative for the model.** [`MATHEMATICAL_SPEC_WORKING.md`](MATHEMATICAL_SPEC_WORKING.md) is the reviewed, formalised transcription of the original notation and is the single source of truth for every equation, symbol, and parameter. The forms shown in this section are an orientation for the reader; where this document and the maths spec differ, the maths spec wins, and implementation follows it (not this section). The maths spec also adds terms not shown here, notably the human-to-mosquito infection probability `c` (maths spec §1).

### 5.2 Multiple species

Vectorial capacity is always modelled per species and then summed: `V = sum_s V_s`. There is a single path — species-specific abundance in, species-specific capacity computed, capacities summed — which prevents species composition from being applied twice by construction, rather than by validating against it.

This subsumes the cases earlier drafts treated separately:

- **Total abundance with species fractions** is input preparation, not a modelling mode: allocate abundance to species (`M · f_s`) before it enters the model, upstream or via a thin helper. It is never a second aggregation step inside the engine.
- **Single-species use** is simply one species in scope.

The package does not emit "effective" single-species-equivalent parameters (one `a`, `p`, `m` standing for a multi-species community). Collapsing several species into one parameter set is a nonlinear, lossy reduction (maths spec §8), distinct from summing capacities. A downstream single-species model consumes per-species outputs and performs its own reduction if it needs one.

### 5.3 Vector control impact

VCI is the proportional change in capacity between two named scenarios, a **reference** and an **alternative**:

```math
VCI = 1 - \frac{V_{\text{alt}}}{V_{\text{ref}}}, \qquad VCI_{pct}=100\times VCI.
```

The comparison is deliberately general: reference and alternative may be any two scenarios. The common and most interpretable case is a no-intervention (or status-quo) reference against an intervention alternative, and that case should be prominent in the documentation and examples — but the same machinery serves, for instance, two intervention packages compared against each other, or two non-intervention futures (e.g. under different climate assumptions). Both scenarios are computed by the same capacity calculation; only which one is named the reference differs.

The reference choice must be recorded in output metadata. The package must warn when the reference is zero or effectively zero, and define behaviour for increases in capacity (`VCI < 0`); see #19.

### 5.4 Candidate v1 component equations

The candidate v1 component equations are specified in [`MATHEMATICAL_SPEC_WORKING.md`](MATHEMATICAL_SPEC_WORKING.md), which is authoritative. That document is the v1 candidate equation set — host encounter and redistribution, the repellency/barrier/killing decomposition of intervention effects, the successful-feeding rate, the mortality-hazard formulation of survival, and parasite development. This section previously restated an earlier, superseded version of those relationships and is not repeated here to avoid a second source that can drift.

Every implemented formula still requires a signed-off equation, parameter definition, domain, unit, source, and independently-computed test case (§10.2). The maths spec's own open items (its §22) are the record of what remains to be settled.

## 6. Component architecture

### 6.0 Two-stage execution

Components divide into two stages, and the division is architectural rather than incidental:

- **Intervention-independent:** microclimate, larval habitat, aquatic and adult population dynamics, abundance per human, attempted feeding rate, and parasite development. None of these depend on which interventions are deployed.
- **Intervention-dependent:** host encounter and redistribution, intervention effects, successful human biting, adult survival, and the capacity equation.

Every scenario in a comparison shares the whole of the first stage. The engine must compute it once and reuse it across scenarios, rather than recomputing per scenario. Population dynamics are expected to dominate runtime, so for a baseline plus three intervention scenarios this is most of the work.

The requirement is as much about correctness as speed. Uncertainty draws must be paired across scenarios, or the uncertainty reported on `VCI` is inflated by the between-scenario variation that in reality cancels. Computing and reusing a shared first stage makes that pairing structural rather than something each component must remember to preserve.

This split also gives the natural boundary for caching and for chunked evaluation of large rasters (§11).

### 6.1 Components and their metadata

A component is **an ordinary R function**: a vectorised operation over arrays (§7.1.1) whose formal arguments are its inputs and whose return value is its output. There is no separate registry object storing a parallel copy of each component's metadata. Duplicated metadata drifts from the code it describes; instead, the description *is* the standard R package apparatus, and tests keep it honest.

The information an earlier draft proposed to register maps onto mechanisms an R package already has:

- **inputs and outputs** — the function signature. Arguments and the return value are named against canonical variables.
- **units, dimensions, and valid ranges** — the shared variable dictionary (§7.2), one entry per canonical variable, referenced by name. This metadata lives with the *variable*, not repeated in every component that touches it.
- **description, assumptions, equations, citation** — the function's roxygen documentation (`@description`, `@details`, `@references`), cross-referring to `ASSUMPTIONS.md` and `EQUATION_DECISIONS.md`.
- **maturity** — a lifecycle badge (§11.3); **version** — the package version.
- **execution stage** (intervention-independent or -dependent, §6.0) — a documented attribute of the component.

A **preset** is then a named list of component functions (§6.2), not an entry in a registry — idiomatic R, printable, each element reachable through its own help page.

Compatibility is **derived** from signatures and the dictionary: two components compose if the variables one produces supply the variables the next requires, in the dictionary's units and dimensions. It is not a hand-maintained matrix of compatible pairs, which would need editing across every component whenever one was added and would silently rot.

Because the human-readable documentation and the machine-checkable behaviour are now the same source viewed two ways, a **test suite enforces their agreement**: every documented parameter exists in the dictionary; every function argument and return is a documented, dictionary-defined variable; declared units and dimensions match what the function consumes and produces. Documentation that disagrees with the code fails the build. (This makes the dictionary, §7.2 / #7, load-bearing: unit and dimension compatibility is derived from it, since it cannot be parsed from prose.)

Declared incompatibility remains available for combinations that are dimensionally valid but scientifically incoherent, which cannot be detected from signatures alone. It is **advisory**: such combinations are documented and warned about, not blocked. A user who composes a non-default set of components has taken responsibility for its coherence; the package's job is to make the consequences visible — through the warning and through hybrid labelling (§6.3) — not to prevent the composition. Dimensional and unit invalidity is different and is still rejected outright.

Proposed component types, grouped by execution stage (§6.0). Each is a slot a preset fills with one implementation; the maths-spec section that defines the quantity is cited for reference, and the maths spec ([`MATHEMATICAL_SPEC_WORKING.md`](MATHEMATICAL_SPEC_WORKING.md)) is authoritative for what each produces.

Every component is evaluated **per species**: it computes its quantity for a given species (as well as per location and time), and capacity is built per species and summed (§5.2). Species-specific inputs — attraction weights, microclimate responses, biting profiles, and so on — enter the relevant components accordingly.

**Intervention-independent** (computed once per comparison, §6.0):

- `microclimate` — species-specific microclimate driving the temperature-dependent components (maths spec §7);
- `larval_habitat` — maximum effective larval habitat `L^max` (§5, §9);
- `population_dynamics` — adult and aquatic-stage dynamics giving adults per unit habitat, from realised habitat and microclimate (§6, §7);
- `abundance` — adults per human `m`, from `L^max`, adult density, and human population, with temporal aggregation (§8);
- `attempted_feeding_rate` — the rate `a*` at which a mosquito attempts to blood-feed, before host choice or protection (§10);
- `biting_profile` — species-specific hourly indoor and outdoor biting-attempt profiles (§12);
- `infection_probability` — human-to-mosquito infection probability `c` (§2);
- `parasite_development` — extrinsic incubation period `ν` (§2); may share an implementation with `infection_probability` (e.g. a temperature-dependent model producing both);
- `baseline_survival` — baseline, climate-dependent adult mortality hazard `μ⁰`, before intervention killing (§17).

**Intervention-dependent** (computed per scenario, §6.0):

- `host_encounter` — host opportunities and pre-intervention destination probabilities (indoor / outdoor / animal), from biting profiles, human availability, and species attraction (§13);
- `intervention_effect` — maps a deployed intervention or combination to the three effect channels *together*: residual accessibility after repellency `R`, residual feeding success `B`, and pathway-specific residual survival `Kᵉ` (§14);
- `resistance_modifier` — insecticide-resistance inputs feeding the intervention mapping (§14);
- `successful_feeding` — successful human blood-feeding rate `a`, assembling `a*` with repellent redistribution, killing, and barrier effects (§15, §16);
- `adult_survival` — total adult mortality hazard `μ` and survival, combining `μ⁰` with intervention-mediated killing (§17);
- `capacity_equation` — vectorial capacity `V` from abundance, feeding, infection, survival, and incubation; stationary or trajectory-based (§1, §4, §17.2).

**Cross-cutting:**

- `uncertainty_engine` — propagation of uncertainty by draws or ensemble (the representation is not yet fixed);
- `vector_competence` — optional/future.

There is deliberately no `species_composition` or `species_aggregation` component — allocating abundance to species is upstream input preparation, and the per-species sum is fixed engine logic, not a swappable model. The earlier flat list also carried a single `human_biting` type (now split into `attempted_feeding_rate` `a*` and `successful_feeding` `a`, since the two differ and `a` is squared in capacity) and separate `intervention_deterrence` / `intervention_barrier` / `intervention_killing` types (now the one `intervention_effect`, since the maths spec has a single intervention model produce `R`, `B`, `Kᵉ` together with no generic per-channel combination rule).

### 6.2 Presets

A preset is a versioned, immutable manifest selecting compatible components and defaults. Planned IDs:

- `va_v1`
- `openmalaria_<version>`
- `malariasimulation_<version>`
- `emod_<version>`
- `vcom_<version>` if included
- user-defined manifests

A preset must be inspectable before execution. Model names alone are insufficient because external implementations evolve; every preset must include a target software version or commit and evidence of equivalence.

### 6.3 Hybrid configurations

Advanced users may replace components within a preset. The package must:

1. display changed assumptions;
2. run compatibility validation, derived from the declared inputs and outputs (§6.1);
3. reject dimensionally or logically invalid combinations;
4. warn on combinations declared scientifically incompatible, or otherwise unvalidated, without blocking them — responsibility for a deliberately non-default composition rests with the user;
5. visibly label outputs as hybrid, not as reproductions of the named source model.

## 7. Data contracts

### 7.1 Canonical dimensions

Inputs should be normalised to explicit dimensions, as applicable:

- `location_id`
- `time`
- `species`
- `scenario`
- `draw`

`intervention` is deliberately **not** a canonical dimension. A scenario contains a set of interventions, so capacity, abundance, survival, and VCI are properties of the scenario as a whole and carry no meaningful intervention index. Interventions are described within the scenario specification (§7.3). Where a diagnostic genuinely attributes an effect to an individual intervention, that is a specific output with its own shape, not a global axis.

`time` denotes an interval with an explicit duration and calendar, not an instant. Almost every modelled quantity is a rate or a probability defined over an interval, and the requirement that results be invariant to the chosen time unit cannot be tested without knowing what a time index represents.

Spatial geometry is attached through a separate keyed object. This prevents hidden raster alignment and makes the engine usable for rasters, polygons, points, and non-spatial tests.

### 7.1.1 Array representation

Variables are held in the core as **arrays over named dimensions**, not as long tables. Long tables are accepted and emitted at the boundaries, where users think in rows.

The reason is scale. Nigeria at 5 km is roughly 37,000 pixels; over twelve months, three species, two scenarios, and one hundred draws that is around 266 million values, or about 2 GB per variable as a numeric array and several times that as a long table carrying index columns. Africa-wide at the same resolution is of the order of 70 GB per variable. A long-format core cannot meet the §11 targets at national scale.

The same array structures serve the full range of workloads without a second code path. A single deterministic calculation across districts for two scenarios — the common case — is the same object with several dimensions of length one, and should run in seconds once district-level parameters are prepared.

Two design constraints follow, and both bind on how components are written rather than on the engine alone:

- **Each cell is independent.** A component computes a value from other values at the same index. Nothing in the core requires a component to see across locations, times, or draws. Where a calculation genuinely is sequential — population dynamics over time is the obvious case — that dependency is confined to the one dimension it acts along and declared as such.
- **Components are vectorised across whole arrays**, not written as scalar functions applied elementwise.

Together these mean a single R implementation of each component can be executed either by base R array arithmetic or, unchanged, by an array backend that parallelises across cells. Dimension order should be chosen with that in mind rather than left to whatever the first implementation happens to produce, since reordering later is a change to every component. Backend support itself is future work and out of scope for v1; see issue #39.

### 7.2 Typed variables

Every variable requires metadata: canonical name, description, unit, scale, support/range, dimensions, missing-data policy, source, license, spatial/temporal resolution, aggregation rule, and provenance checksum/version.

Use explicit names in public APIs, avoiding bare symbols except in equation documentation. Examples: `daily_human_biting_rate`, `daily_adult_survival_probability`, `extrinsic_incubation_days`, `human_population_density`, `larval_habitat_index`.

### 7.3 Intervention scenario schema

Minimum fields:

- scenario ID and reference scenario ID;
- intervention type and product/class;
- coverage or effective coverage;
- location/time support;
- start/end dates or time index;
- resistance mechanism/phenotype inputs where relevant;
- decay/age information where relevant;
- source and uncertainty;
- overlap rule for intervention combinations.

Coverage must not be conflated with biological efficacy. The transformation from coverage to encounter/effect belongs to an explicit component.

### 7.4 Missing data

No silent imputation. Policies must be explicit: `error`, `propagate_na`, `use_documented_default`, or a user-supplied imputation component. Outputs include missingness and default-use diagnostics.

## 8. Public API sketch

High-level functions, names provisional:

```r
model <- vc_model(preset = "va_v1")
inspect_model(model)
validate_inputs(vector_data, scenarios, model)

capacity <- compute_capacity(
  model = model,
  vector_data = vector_data,
  scenarios = scenarios,
  uncertainty = "draws"
)

result <- compute_vci(capacity, reference = "status_quo")

plot(result, quantity = "vci_percent")
write_vci(result, path = "outputs/")
provenance(result)
```

Capacity and the scenario comparison are separate steps. Two of the six user archetypes in §3 — the vector scientist inspecting biological plausibility, and the mechanistic modeller requesting parameter layers — want capacity and its intermediates without any comparison, and §1 lists baseline parameters and baseline capacity as deliverables in their own right. A single call from data to VCI would oblige those users to run a comparison they do not want.

Separating the steps also places the reference-scenario semantics (§5.3) in one explicit function rather than in an argument threaded through the whole calculation, and gives the requirement that draws be paired across scenarios a single place to be enforced.

Advanced composition:

```r
model <- vc_model("va_v1") |>
  replace_component("adult_survival", "emod_<version>") |>
  validate_model(strict = TRUE)
```

Layer access and adapters:

```r
available_layers()
get_default_layers(area, time, species, variables)
as_vc_data(x)
as_terra(result)
as_sf(result)
```

## 9. Result object

A `vc_result` contains:

- scenario and reference values of species-specific and aggregate capacity;
- VCI proportion and percent;
- requested intermediate parameters;
- uncertainty summaries and optionally draws;
- warnings, boundary cases, missing/default masks;
- complete preset/component manifest;
- input provenance and checksums;
- package/R/dependency versions;
- spatial/temporal metadata;
- machine-readable export manifest.

Metadata, diagnostics, and uncertainty summaries are held eagerly; draws are held lazily. Everything in the list above except the draws is small, while draws over a national raster are of the order of gigabytes per variable. Requiring the whole object to be resident in order to call `provenance()` or print a summary would make routine inspection impractical.

Accordingly, the on-disk layout written by `write_vci()` is a first-class format rather than an export of an in-memory object, and the in-memory result may be a handle onto it. This serves the dashboard and non-R integration requirement in §11 directly, and makes chunked evaluation of large rasters a natural consequence of the result design rather than something added on top of it.

## 10. Validation and testing

### 10.1 Scientific invariants

At minimum:

- `0 < p < 1`, `a >= 0`, `m >= 0`, `v > 0` under the Garrett-Jones component;
- zero abundance or biting gives zero capacity;
- increasing abundance increases capacity linearly when other values are fixed;
- increasing intervention killing cannot increase survival in components intended to be monotone;
- no-effect intervention reproduces baseline;
- identical reference and scenario gives `VCI = 0`;
- species aggregation does not double-weight composition;
- units and temporal scales are compatible.

### 10.2 Test layers

- unit tests for equations and validators;
- analytic edge cases;
- stored test cases whose correct answers were worked out independently of the implementation and signed off by a scientist;
- comparison tests against independent calculations;
- cross-implementation test cases for OpenMalaria, malariasimulation, EMOD, and VCOM presets;
- spatial alignment and aggregation tests;
- uncertainty propagation tests;
- performance tests on representative national rasters;
- end-to-end vignettes.

Equivalence claims must define tolerances and the external software version/commit used to create the test cases.

Stored test cases only detect a misread equation if their expected values were derived from the equations rather than from the code. Where the same person or agent both implements a component and computes its expected values from the same reading of the specification, a misreading is reproduced in both and the test confirms it rather than catching it. Expected values must be derived from `EQUATION_DECISIONS.md` and the source documents, independently of `R/`.

## 11. Performance and deployment

Two workloads are representative, and both use the same array structures (§7.1.1):

- **The common case:** a single deterministic calculation across districts for two scenarios. This should complete in seconds on a standard laptop once district-level parameters have been prepared, and is the workload most analyst usage will consist of.
- **The demanding case:** a multi-draw calculation at pixel level, which is among the most computationally expensive applications of the framework.

Sizing decisions should be made against the first, not only the second. A design that is acceptable only at pixel-and-draw scale risks making the common case slower and more memory-hungry than it needs to be.

- Prototype national scenario calculations should complete in seconds to minutes on a standard laptop for typical administrative-area workflows.
- Large raster/cube workflows should support chunking, lazy loading, and optional parallelism without changing results.
- Core engine should avoid hard dependency on a web service.
- Package should work offline when users provide local inputs. Default layer retrieval may require a separate download/cache adapter.
- Use serialisable configuration and result formats suitable for `plumber`, Shiny, or non-R reimplementation.

### 11.1 Reproducibility under parallelism

"Without changing results" is not automatic for stochastic calculations. If draws are taken from a single sequential random number stream, their values depend on evaluation order, and evaluation order depends on how work was divided between workers — so the same seed gives different answers on a different machine, or after a change to chunk size.

Each draw's seed must therefore be derived deterministically from a root seed and the draw index, so that the value of a draw depends on nothing but the root seed. Stated now this is a one-line constraint on the uncertainty engine; discovered later it is an intermittent, hard-to-attribute irreproducibility in published results.

### 11.2 Error reporting

Validation is pervasive (§2, §6.3, §7.4, §10.1) and the form of its failures is part of the public interface:

- Failures are signalled as classed conditions, so that a caller — particularly a dashboard or a script — can distinguish incompatible units from incompatible components from misaligned rasters programmatically, rather than by matching message text.
- Input validation accumulates problems and reports them together rather than stopping at the first. A user supplying a national dataset with many issues should see them in one pass, not discover them one run at a time.

### 11.3 API stability

Integration is invited from Phase 4 (§14), well before the stable release targeted for mid-2028. Integrators therefore need a per-function statement of stability rather than having to infer it from the version number or discover it through breakage.

Public functions carry an explicit lifecycle stage from the first release, with the whole public API marked experimental initially. Promotion to stable is a deliberate act, recorded in `NEWS.md`, and thereafter constrains what may change without a major version. The lifecycle and deprecation policy in §12 documents the guarantees each stage carries.

### 11.4 Provenance cost

§9 requires input provenance and checksums. Hashing multi-gigabyte rasters on every run is slow enough that users would disable it, which defeats its purpose.

The policy must therefore state what is hashed and when: file-level hashes recorded once at ingestion rather than recomputed per run, with source identity and modification time recorded as a documented fallback where hashing is impractical. It must also define behaviour for lazily-loaded inputs that reference files which may have changed since the reference was created, which is the normal case with `terra`.

## 12. Documentation

Required before a stable release:

- getting started vignette;
- national administrative-area scenario tutorial;
- raster scenario tutorial;
- scientific methods and equation reference;
- variable dictionary and units;
- intervention schema guide;
- uncertainty guide;
- model/preset comparison guide;
- assumptions and limitations register;
- extension guide for new components;
- reproducibility/provenance guide;
- dashboard integration guide;
- contributor guide and lifecycle/deprecation policy;
- software paper draft.

## 13. Monitoring and evaluation instrumentation

The package must make project success measurable without collecting sensitive user data:

- public repository releases, stars, forks, issues, contributors, citations, and available download metrics;
- opt-in, non-identifying usage feedback only;
- structured testimonial/case-study template recording organisation, country, decision context, workflow, package version, and perceived validity/utility;
- registry of downstream integrations, including MAP, SNT workflows, and mechanistic models;
- reproducible examples showing IR layers and baseline vectorial parameter maps used in calculation.

No telemetry should be enabled by default.

## 14. Delivery plan inferred from dependencies

The contractual target for the R package and most VCI outputs is 1 February 2029, but this is not a useful engineering deadline because Outputs 1.1.1 and 1.1.3 depend on a working implementation. The following internal plan is inferred:

### Phase 0: minimal working example (milestone 0)

A single end-to-end run, built first as a smoke test — before the science is signed off — to surface architecture and integration problems while they are still cheap to fix.

- compute VCI for one small country at district level, comparing three scenarios: no intervention, business-as-usual (approximating current coverage), and one hypothesised alternative;
- use mocked, locally-cached inputs — vector-biology and current-coverage rasters, GADM district boundaries, and a district×coverage table for the alternative — with no data portal or download;
- use ballpark parameters and a clearly-labelled stub for the intervention→(R,B,K) mapping; **outputs are illustrative only and must not be read as a real analysis**;
- retain the example as a committed, deterministic integration test.

This deliberately precedes the specification work below. It exercises the input contract, capacity equation, species sum, and scenario comparison end to end, so that decisions in the later phases are informed by a working slice rather than made on paper.

### Phase 1: specification and alignment, July–September 2026

- approve scientific notation, candidate v1 equations, input dictionary, architecture, and licensing;
- define user archetypes and priority workflows;
- create repository scaffolding, ADRs, issue taxonomy, and minimal CI.

### Phase 2: executable scientific kernel, October–December 2026

- implement capacity equation, species aggregation, VCI comparison, typed tabular inputs, validation, and provenance;
- create test cases whose correct answers are worked out independently of the implementation;
- publish an internal `0.1.0` prototype.

### Phase 3: VA v1 vertical slice, January–June 2027

- implement the first coherent `va_v1` preset, intervention schema, core intervention effects, spatial adapters, and uncertainty draws;
- link or consume first larval-habitat products due 1 February 2027;
- deliver at least one reproducible national example and seek partner usability feedback;
- release public alpha/beta by June 2027.

### Phase 4: downstream integration and model mapping, July–December 2027

- support MAP national/Africa-wide prototypes and parameter cube exports;
- complete documented mappings of OpenMalaria, malariasimulation, and EMOD components;
- implement at least one externally verified model-aligned preset;
- stabilise extension API and release candidate.

### Phase 5: IR and comparative implementations, January–June 2028

- integrate joint genotypic/phenotypic IR outputs associated with the model paper due 1 February 2028;
- add and verify remaining priority presets and model comparison documentation;
- run user testing with national/TSU analysts and dashboard integrators;
- target stable `1.0.0` by June 2028.

### Phase 6: adoption, hardening, paper, and final products, July 2028–January 2029

- maintain backward compatibility, improve performance/accessibility, close evidence gaps;
- complete software paper and release archive/DOI;
- demonstrate downstream integrations and M&E evidence;
- submit all contractual outputs by 1 February 2029.

**Critical internal deadline:** a stable working version should exist no later than mid-2028, leaving at least six months for integration, adoption, evaluation, and publication.

## 15. Risks and mitigations

- **Equations remain ambiguous:** maintain an equation decision log; do not encode uncertain transcription as stable behaviour.
- **External model drift:** version presets against releases/commits and run scheduled comparison tests.
- **Sparse or restricted data:** separate engine from default data products; preserve licensing and permit national/private layers without uploading them.
- **False precision:** propagate uncertainty, expose default use, and provide biological diagnostics.
- **Combinatorial model choices:** provide coherent presets, restrict casual mixing, and label hybrids.
- **Raster scale and memory:** keep a non-spatial kernel and use chunked adapters.
- **Low uptake:** design with user archetypes, deliver vertical slices early, integrate with existing dashboards/workflows, and document realistic examples.
- **AI-agent contribution risk:** require small issues, tests, provenance, review ownership, and no scientific assumption changes without an ADR and domain review.

## 16. Decisions required

Open decisions are tracked as GitHub issues labelled `scientific-decision` and `infrastructure`, not in this list, so the two cannot drift. This section records only what has been *resolved* since v0.1, plus the residual items that do not yet map cleanly to an issue.

**Resolved since v0.1:**

- package name, repository, and licence — `vci`, `idem-lab/vci`, MIT;
- the nature of `L` — maximum effective larval habitat: unitless, static, latent (maths spec §5), not a physical density or index;
- where species composition enters — per-species modelling then summation, single path (§5.2);
- compatibility policy for component selection — derived from signatures and the variable dictionary, with advisory scientific incompatibility (§6.1);
- core in-memory representation — arrays over named dimensions (§7.1.1).

**Tracked as issues** (non-exhaustive): reference scenarios and `V0 = 0` (#19); canonical resolution and default-data distribution (#21, #40); priority interventions for v1 (#22); intervention→effect mapping (#17); uncertainty representation (#20); the equation sign-off items (#6, #12, #13, #14). Array dimension order is tracked with the array-backend work (#39).

**Still open, tracked separately:** the first external implementation to target for an equivalence preset; the minimum viable dashboard/integration API; and accessibility and localisation requirements for country users.

## 17. Proposed supporting repository documents

- `DESIGN.md`: this specification.
- `MODEL_CATALOGUE.yml`: machine-readable components, presets, assumptions, and maturity.
- `VARIABLE_DICTIONARY.yml`: variables, units, dimensions, ranges, and sources.
- `INTERVENTION_SCHEMA.json`: scenario validation schema.
- `ASSUMPTIONS.md`: scientific assumptions and implications.
- `EQUATION_DECISIONS.md`: transcription and scientific sign-off log.
- `ROADMAP.md`: milestones and release gates.
- `USER_ARCHETYPES.md`: archetypes, tasks, constraints, and success criteria.
- `UI_WORKFLOWS.md`: R, dashboard, and integration workflows.
- `VALIDATION_PLAN.md`: fixtures, comparison models, tolerances, and reviewers.
- `adr/`: architecture and scientific decision records.

## 18. Source traceability

This draft draws on:

- Vector Atlas II Investment Document, particularly Intermediate Outcome 1.1, Outputs 1.1.1–1.1.3, delivery dates, and monitoring/evaluation table.
- `mapping_vectorial_capacity.txt`, including the Garrett-Jones decomposition and candidate component relationships.
- the original handwritten equations, since transcribed, reviewed, and formalised into [`MATHEMATICAL_SPEC_WORKING.md`](MATHEMATICAL_SPEC_WORKING.md).

The mathematics of those original notes has been superseded as a working reference by the maths spec, which is now the single source of truth for the model (§5.1). The original photograph is not held in this repository. Where this design document and the maths spec differ, the maths spec is authoritative.
