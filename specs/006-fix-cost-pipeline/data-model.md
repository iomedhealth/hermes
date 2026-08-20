# Data Model: Spanish Ground-Source Healthcare Cost Catalogs & INE Indices

**Feature Branch**: `006-fix-cost-pipeline` | **Date**: Wed Aug 19 2026 | **Spec**: [specs/006-fix-cost-pipeline/spec.md](spec.md)

## 1. Core Entities & Schemas

### A. CostRecord (Canonical Tariff Record)

Exported into `data/costs_spain.csv`, `data/costs_spain.parquet`, and `data/costs_spain.json`.

| Field Name | Type | Nullable | Description / Validation Rules | Example |
|---|---|---|---|---|
| `cost_id` | `VARCHAR(50)` | No | Unique sequential primary key formatted as `<ccaa_prefix>-cost-<05d>` | `and-cost-00044` |
| `description` | `VARCHAR(1000)` | No | Cleaned, uppercase clinical service description without non-sanitary text or wrapping fragments | `CRANEOTOMÍA POR TRAUMA CON CC` |
| `cost_group` | `VARCHAR(200)` | No | Legal category or gazette annex designation | `Precios Públicos / Tasas por Asistencia Sanitaria` |
| `setting` | `VARCHAR(50)` | No | Clinical setting: `Inpatient`, `ICU`, `Outpatient`, `Emergency`, `Diagnostics`, `Procedures`, `Primary Care` | `Inpatient` |
| `specialty` | `VARCHAR(100)` | No | Medical or surgical specialty | `Neurocirugía` |
| `unit_type` | `VARCHAR(50)` | No | Unit cost metric: `per_episode`, `per_diem`, `per_visit`, `per_procedure`, `per_test`, `per_session` | `per_episode` |
| `cost_original` | `DECIMAL(12,2)` | No | Ground-source reference tariff in baseline Euros (range: 0.50 € to 250,000.00 €) | `16168.36` |
| `year_original` | `INTEGER` | No | Year of gazette publication or baseline cost study (e.g., 2013–2024) | `2024` |
| `cost_updated` | `DECIMAL(12,2)` | No | Escalated tariff in constant 2026 Euros via INE Healthcare CPI | `16836.88` |
| `year_updated` | `INTEGER` | No | Target analysis year (constant 2026) | `2026` |
| `ccaa` | `VARCHAR(100)` | No | Autonomous Community, INGESA, or National Casemix | `Andalucía` |
| `legal_source` | `VARCHAR(500)` | No | Official legal title of decree, order, or resolution | `Orden de 24 de mayo de 2024...` |
| `source_url` | `VARCHAR(500)` | No | Public URL of gazette document | `https://www.juntadeandalucia.es/...` |
| `code_std` | `VARCHAR(100)` | Yes (empty string if none) | Standardized code with valid prefix (`APR-GRD:`, `ICD-9-CM:`, `ICD-10-PCS:`, `CN:`, `SAP:`, `REGIONAL:`) | `APR-GRD:020-2` |
| `omop_domain` | `VARCHAR(50)` | No | OMOP CDM Domain: `Visit`, `Procedure`, `Measurement`, `Drug` | `Visit` |

---

### B. INE Index Record (`IneIndexRecord`)

Exported into `data/ine_indices_sanidad.csv`, `data/ine_indices_sanidad.parquet`, and `data/ine_indices_sanidad.json`.

| Field Name | Type | Nullable | Description | Example |
|---|---|---|---|---|
| `ecoicop_code` | `VARCHAR(20)` | No | ECOICOP classification code (`06`, `06.1`, `06.2`, `06.3`) | `06` |
| `series_name` | `VARCHAR(200)` | No | Full descriptive title from INE Table 50913 | `Nacional. Sanidad. Índice.` |
| `year` | `INTEGER` | No | Calendar year (2002 to 2026) | `2024` |
| `annual_index` | `DECIMAL(6,2)` | No | Average annual price index (Base 2021 = 100) | `105.09` |
| `factor_to_2026` | `DECIMAL(6,4)` | No | Multiplier to escalate baseline cost to constant 2026 Euros | `1.0413` |
| `is_projected` | `BOOLEAN` | No | Flag indicating estimated/projected rate | `false` |

---

## 2. Standardized Code Prefix Specifications (`code_std`)

| Prefix | Target Coding System | Format Grammar | Valid Example | Invalid Example (Rejected) |
|---|---|---|---|---|
| `APR-GRD:` | All-Patient Refined DRG | `^APR-GRD:\d{1,4}(?:-[1-4])?$` | `APR-GRD:020-2`, `APR-GRD:001` | `APR-GRD:4-18,9530` (corrupted weight) |
| `ICD-9-CM:` | ICD-9 Clinical Modification Procedures | `^ICD-9-CM:\d{2}\.\d{1,2}$` | `ICD-9-CM:04.43`, `ICD-9-CM:13.41` | `ICD-9-CM:999` |
| `ICD-10-PCS:` | ICD-10 Procedure Coding System | `^ICD-10-PCS:[0-9A-HJ-NP-Z]{7}$` (Valid Section 0-9, B-D, F-H, X) | `ICD-10-PCS:0210093`, `ICD-10-PCS:0TT90ZZ` | `ICD-10-PCS:DRENAJE` (Spanish word), `ICD-10-PCS:PD00002` |
| `CN:` | Código Nacional Farmacéutico | `^CN:\d{6}$` | `CN:712345` | `CN:12` |
| `SAP:` | SAP Material/Service Code | `^SAP:\d{7}$` | `SAP:7020640` | `SAP:123` |
| `REGIONAL:` | Verified Regional Procedure Nomenclature | `^REGIONAL:(?:CMA\d+|V03[A-Z0-9]+|LQ\d+[A-Z]?|E03\.[0-9\.]+|A\.\d\.[0-9\.]+|[A-Z0-9\.\-]{3,15})$` | `REGIONAL:CMA001`, `REGIONAL:V03PVC001` | `REGIONAL:B1`, `REGIONAL:DOG`, `REGIONAL:2.-` |

---

## 3. Clinical Setting & OMOP Domain Mapping Matrix

```
+-------------------+----------------+---------------+-----------------------------------------------+
| Clinical Setting  | OMOP Domain    | Unit Type     | Typical Clinical Activities                   |
+-------------------+----------------+---------------+-----------------------------------------------+
| Inpatient         | Visit          | per_episode   | APR-GRD medical admissions, surgical stays    |
|                   |                | per_diem      | Daily hospitalization per diem stays          |
+-------------------+----------------+---------------+-----------------------------------------------+
| ICU               | Visit          | per_diem      | Intensive care, resuscitation, critical care  |
|                   |                | per_episode   | ICU admission episodes                        |
+-------------------+----------------+---------------+-----------------------------------------------+
| Outpatient        | Visit          | per_visit     | Specialist consultations, follow-up visits    |
|                   |                | per_session   | Physiotherapy, rehabilitation, psychotherapy  |
+-------------------+----------------+---------------+-----------------------------------------------+
| Emergency         | Visit          | per_visit     | Hospital emergency department attendances     |
+-------------------+----------------+---------------+-----------------------------------------------+
| Primary Care      | Visit          | per_visit     | General practitioner, pediatrics, AP nursing  |
+-------------------+----------------+---------------+-----------------------------------------------+
| Diagnostics       | Measurement    | per_test      | CT, MRI, Ultrasound, Clinical Lab, Biopsy     |
+-------------------+----------------+---------------+-----------------------------------------------+
| Procedures        | Procedure      | per_procedure | Ambulatory surgery (CMA), interventional acts |
+-------------------+----------------+---------------+-----------------------------------------------+
```

---

## 4. Registry Metadata Entity (`registries.yml`)

```yaml
sources:
  - id: string               # e.g., "and-2024-precios"
    ccaa: string             # e.g., "Andalucía"
    scope: string            # "regional" | "national"
    category: string         # Tariff description
    legal_title: string      # Full gazette title
    gazette: string          # Name of official journal
    gazette_number: int      # Optional issue number
    publication_date: string # "YYYY-MM-DD"
    year: int                # Baseline tariff year
    url_gazette: string      # Portal URL
    url_pdf: string          # Direct PDF download link
    url_data: string         # Direct data endpoint
    file_format: string      # "pdf" | "html" | "xlsx" | "csv" | "json"
```
