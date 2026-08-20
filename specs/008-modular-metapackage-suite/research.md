# Technical Research & Decisions: Modular Metapackage Suite

## 1. Monorepo & Subdirectory Structure

### Decision
Adopt a standard R monorepo structure with sub-packages housed under `packages/<PackageName>` and an umbrella metapackage at the repository root.

### Rationale
- Standard package managers (`pak`, `remotes`, `devtools`) natively support Git subdirectories via `subdir = "packages/..."`.
- The root `DESCRIPTION` allows users who run `remotes::install_github("iomedhealth/hermes")` to install the full suite without needing to learn the `subdir` parameter.
- Isolating HCRU into `CohortUtilisation` allows researchers without simulation dependencies (`hesim`, `BCEA`, `Cyclops`) to use the library on restricted or lightweight server nodes.

---

## 2. Metapackage Loading Mechanism (`zzz.R`)

### Decision
Implement `.onAttach()` in `R/zzz.R` at the root metapackage to dynamically attach `CohortUtilisation`, `CohortCosts`, and `CohortEconomics` using `requireNamespace()` and `attachNamespace()`, mirroring the `tidyverse` / `tidymodels` startup banner.

### Banner Example
```text
── Attaching packages ────────────────────────────────── hermes 0.3.0 ──
✔ CohortUtilisation 0.3.0     ✔ CohortEconomics   0.3.0
✔ CohortCosts       0.3.0
```

---

## 3. Package Names & Domain Boundaries

### Decision
1. **`CohortUtilisation`**: PascalCase, matches DARWIN EU standard (`DrugUtilisation`, `CohortCharacteristics`). Covers Stage 1 (Cohort Generation) & Stage 2 (Resource Utilization).
2. **`CohortCosts`**: PascalCase. Covers Stage 2 (Direct Medical Costs & Unit Tariffs).
3. **`CohortEconomics`**: PascalCase. Covers Stage 3 (Propensity Scores), Stage 4 (Health States & Trajectories), Stage 5 (Markov & PSA Simulations), and Stage 6 (Cost-Effectiveness Analysis).
4. **`hermes`**: Lowercase root metapackage.

---

## 4. Shared Documentation Strategy (`pkgdown`)

### Decision
A single root `_pkgdown.yml` configures a unified documentation website, grouping functions across all 3 sub-packages into distinct domain sections and linking end-to-end HEOR vignettes.
