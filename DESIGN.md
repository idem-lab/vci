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
- Human biting, adult survival, adult-to-larval ratio/population dynamics, larval habitat, parasite development, species composition, host availability, human indoor presence, and intervention-effect components.
- Indoor intervention effects separated into deterrence/barrier, killing, and feasible interaction effects.
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

\[
V_{s,i,t} = \frac{m_{s,i,t} a_{s,i,t}^{2} p_{s,i,t}^{v_{s,i,t}}}{-\log(p_{s,i,t})}.
\]

The whiteboard writes the species form as `V_s = m_s a_s^2 p_s^v / -ln(p_s)` and defines:

\[
m_{s,i,t}=M_{s,i,t}/H_{i,t}, \qquad M_{s,i,t}=\bar n_{s,i,t}L_{s,i,t}.
\]

Here `H` is human population or density, `L` is larval habitat availability/scale, and `n_bar` is average adult mosquitoes per unit larval habitat. The notes also describe `n_bar` through a dynamic aquatic/adult-stage model. Exact discrete-time equations and symbols require scientific review against the whiteboard before implementation.

### 5.2 Multiple species

The project documents describe overall capacity as the sum of species-specific contributions. The implementation must not ambiguously apply species fractions twice. It must support and distinguish:

- absolute species abundance inputs, where `V = sum_s V_s`;
- total abundance plus species fractions, where species abundance is first allocated by fractions and then summed;
- model-specific aggregation required by single-species downstream models.

### 5.3 Vector control impact

For reference scenario `0` and intervention scenario `1`:

\[
VCI = 1 - \frac{V_1}{V_0}, \qquad VCI_{pct}=100\times VCI.
\]

The API must permit status quo, no-intervention, or another scenario as the reference and label that choice in output metadata. It must warn when the reference is zero or effectively zero and define behaviour for increases in capacity (`VCI < 0`).

### 5.4 Candidate v1 component equations

The draft notes and whiteboard indicate:

- human availability: `N_in = H * I`, `N_out = H * (1-I)`;
- indoor/outdoor/non-human encounter probabilities are normalised functions of host availability and species preferences;
- intervention-adjusted human biting combines indoor and outdoor opportunities, with indoor barrier/repellency effects;
- adult survival combines climate-dependent baseline survival with feeding, indoor encounter, and killing effects;
- larval habitat is baseline availability modified by larval source management;
- climatic components of activity, aquatic development/survival, fecundity, baseline biting, survival, and parasite development are functions of species-specific microclimate;
- intervention effects may use multiplicative residual-effect terms such as `1 - gamma * coverage`, grouped by repellency (`R`), barrier (`B`), killing (`K`), and larval-source-management effects.

These are **candidate v1 equations**, not frozen requirements. Every implemented formula requires a signed-off equation, parameter definition, domain, unit, source, and test fixture.

## 6. Component architecture

### 6.0 Two-stage execution

Components divide into two stages, and the division is architectural rather than incidental:

- **Intervention-independent:** microclimate, larval habitat, aquatic and adult population dynamics, abundance per human, attempted feeding rate, and parasite development. None of these depend on which interventions are deployed.
- **Intervention-dependent:** host encounter and redistribution, intervention effects, successful human biting, adult survival, and the capacity equation.

Every scenario in a comparison shares the whole of the first stage. The engine must compute it once and reuse it across scenarios, rather than recomputing per scenario. Population dynamics are expected to dominate runtime, so for a baseline plus three intervention scenarios this is most of the work.

The requirement is as much about correctness as speed. Uncertainty draws must be paired across scenarios, or the uncertainty reported on `VCI` is inflated by the between-scenario variation that in reality cancels. Computing and reusing a shared first stage makes that pairing structural rather than something each component must remember to preserve.

This split also gives the natural boundary for caching and for chunked evaluation of large rasters (§11).

### 6.1 Registry

Each component implementation is registered with:

- `component_type`;
- `implementation_id` and semantic version;
- citation/source;
- equations or algorithm reference;
- required and optional inputs;
- output names, units, dimensions, and valid ranges;
- assumptions and known limitations;
- execution stage: intervention-independent or intervention-dependent (§6.0);
- declared incompatibilities, as an exception only (see below);
- uncertainty support;
- maturity: `experimental`, `candidate`, `stable`, or `deprecated`.

A component is defined by its **declared inputs and outputs**, named against the shared variable dictionary (§7.2), together with the parameter definitions it requires. That declaration is the interface: it is what the registry stores, what the engine dispatches on, and what the extension guide (§12) documents. An implementation is a vectorised function over arrays (§7.1.1) plus its registration record.

Compatibility between components is therefore **derived** rather than enumerated: two components compose if what one produces satisfies what the next requires, in the right units and over the right dimensions. It is not maintained as a hand-written list of compatible pairs. With many component types and several implementations of each, a pairwise matrix would require an edit to every existing component whenever one was added, and any entry left stale would silently either block a valid combination or admit an invalid one.

Declared incompatibility remains valuable for combinations that are dimensionally valid but scientifically incoherent, which cannot be detected from the declarations alone. It is **advisory**: such combinations are documented and warned about, not blocked. A user who deliberately composes a non-default set of components has taken on responsibility for its coherence, and the package's obligation is to make the consequences visible — through the warning and through hybrid labelling (§6.3) — rather than to prevent the composition. Dimensional and unit invalidity is a different matter and is still rejected outright.

Proposed component types:

- `species_composition`
- `larval_habitat`
- `adult_larval_dynamics`
- `host_encounter`
- `human_biting`
- `adult_survival`
- `parasite_development`
- `intervention_deterrence`
- `intervention_barrier`
- `intervention_killing`
- `resistance_modifier`
- `vector_competence` (optional/future)
- `capacity_equation`
- `species_aggregation`
- `uncertainty_engine`

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

Integration is invited from Phase 3 (§14), well before the stable release targeted for mid-2028. Integrators therefore need a per-function statement of stability rather than having to infer it from the version number or discover it through breakage.

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

### Phase 0: specification and alignment, July–September 2026

- approve scientific notation, candidate v1 equations, input dictionary, architecture, and licensing;
- document outcomes of the intended early-2026 alignment meeting, or run a replacement technical alignment process if not completed;
- define user archetypes and priority workflows;
- create repository scaffolding, ADRs, issue taxonomy, and minimal CI.

### Phase 1: executable scientific kernel, October–December 2026

- implement capacity equation, species aggregation, VCI comparison, typed tabular inputs, validation, and provenance;
- create test cases whose correct answers are worked out independently of the implementation;
- publish an internal `0.1.0` prototype.

### Phase 2: VA v1 vertical slice, January–June 2027

- implement the first coherent `va_v1` preset, intervention schema, core intervention effects, spatial adapters, and uncertainty draws;
- link or consume first larval-habitat products due 1 February 2027;
- deliver at least one reproducible national example and seek partner usability feedback;
- release public alpha/beta by June 2027.

### Phase 3: downstream integration and model mapping, July–December 2027

- support MAP national/Africa-wide prototypes and parameter cube exports;
- complete documented mappings of OpenMalaria, malariasimulation, and EMOD components;
- implement at least one externally verified model-aligned preset;
- stabilise extension API and release candidate.

### Phase 4: IR and comparative implementations, January–June 2028

- integrate joint genotypic/phenotypic IR outputs associated with the model paper due 1 February 2028;
- add and verify remaining priority presets and model comparison documentation;
- run user testing with national/TSU analysts and dashboard integrators;
- target stable `1.0.0` by June 2028.

### Phase 5: adoption, hardening, paper, and final products, July 2028–January 2029

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

1. Package name, repository, owners, governance, and licence.
2. Canonical notation and exact v1 equations, especially adult/larval dynamics and intervention interactions.
3. Whether `L` is a physical density, habitat index, or latent scale in each implementation.
4. Whether and where species fractions enter abundance and aggregation.
5. Definition of baseline/reference scenarios and expected handling of `V0 = 0`.
6. Canonical spatial and temporal resolution of distributed default products.
7. Default data distribution, caching, and versioning mechanism.
8. Priority interventions and products for v1.
9. Priority external implementation for the first equivalence preset.
10. Uncertainty representation: draws, moments, ensembles, or a combination.
11. Compatibility policy for hybrid component selection.
12. Minimum viable dashboard/integration API.
13. Accessibility, localisation, and offline-use requirements for country users.
14. Dimension order of the core arrays, chosen to suit array-backend execution (§7.1.1).

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
- `maths.jpg`, including the species-specific equation, parameter-definition box, intervention-effect groupings, and estimation notes.

Where the photograph or draft notes are ambiguous, this document records a design requirement or open decision rather than asserting a final equation.
