# Data Model: Spanish Ground-Source Healthcare Cost Extraction

**Feature**: Decouple Cost Ingestion & Modernize Airflow Pipeline  
**Date**: Wed Aug 19 2026

---

## 1. Entities & Data Structures

### `CostRecord` (Standard Normalized Tariff Record)
| Field | Type | Required | Description / Constraints |
| :--- | :--- | :--- | :--- |
| `cost_id` | `str` | Yes | Unique ID formatted as `<ccaa_prefix>-cost-<05d>` (e.g. `and-cost-00001`) |
| `description` | `str` | Yes | Standardized, uncorrupted clinical service description with joined multi-lines |
| `cost_group` | `str` | Yes | Gazette category or tariff section (e.g. `Asistencia Especializada`) |
| `setting` | `str` | Yes | Clinical setting: `Inpatient`, `ICU`, `Outpatient`, `Emergency`, `Diagnostics`, `Procedures`, `Primary Care` |
| `specialty` | `str` | Yes | Medical or surgical specialty |
| `cost_original` | `float` | Yes | Original tariff value in source currency (€), > 0 and < 250,000.0 |
| `cost_updated` | `float` | Yes | Inflated/escalated tariff to Target Year (2026) using ECOICOP 06 series |
| `unit_type` | `str` | Yes | Utilization unit: `per_episode`, `per_day`, `per_visit`, `per_procedure`, `per_test`, `per_item` |
| `currency` | `str` | Yes | `EUR` |
| `year` | `int` | Yes | Baseline gazette publication/tariff year (e.g. 2024) |
| `ccaa` | `str` | Yes | Autonomous community name or `National` |
| `scope` | `str` | Yes | `regional` or `national` |
| `code_std` | `str` | Yes | Canonical code: `APR-GRD:*`, `ICD-9-CM:*`, `ICD-10-PCS:*`, `CN:*`, `SAP:*`, `REGIONAL:*` |
| `omop_domain` | `str` | Yes | OMOP CDM domain: `Visit`, `Procedure`, `Measurement`, `Drug` |
| `source_url` | `str` | Yes | Gazette PDF, Excel, or HTML reference URL |

---

### `IneIndexRecord` (Canonical Inflation Index Series)
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `year` | `int` | Yes | Calendar year (2002–2026) |
| `annual_index` | `float` | Yes | Base 2021=100 annual price index value |
| `multiplier_to_2026` | `float` | Yes | Escalation multiplier: `Index_2026 / Index_Year` |
| `series_code` | `str` | Yes | `ECOICOP_06` (Sanidad), `ECOICOP_06_2` (Ambulatorio), `ECOICOP_06_3` (Hospitalario) |
| `base_year` | `int` | Yes | Base year reference (`2021`) |

---

### `DownloadedSource` (Ingestion Intermediate Result)
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `source_id` | `str` | Yes | Unique identifier matching `registries.yml` |
| `file_path` | `str` | Yes | Local absolute path in `data/raw/` |
| `file_format` | `str` | Yes | `pdf`, `xlsx`, `html`, `json` |
| `size_bytes` | `int` | Yes | Downloaded file size in bytes |
| `status` | `str` | Yes | `downloaded`, `cached`, `skipped`, `error` |
