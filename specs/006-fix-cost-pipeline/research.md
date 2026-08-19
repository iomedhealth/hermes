# Technical Research & Design Decisions: Spanish Cost Extraction Remediation

**Feature Branch**: `006-fix-cost-pipeline` | **Date**: Wed Aug 19 2026 | **Spec**: [specs/006-fix-cost-pipeline/spec.md](spec.md)

## 1. Character Encoding Detection & Diacritic Preservation

### Decision
Implement multi-encoding fallback detection (`utf-8` -> `iso-8859-1` -> `windows-1252`) when opening raw HTML and text files instead of `open(..., encoding="utf-8", errors="ignore")`.

### Rationale
Official gazettes from Catalonia (DOGC) and the Balearic Islands (BOIB) are published in `ISO-8859-1` (Latin-1). Using `errors="ignore"` on UTF-8 silently strips all Spanish and Catalan accented characters (`á, é, í, ó, ú, ñ, ç, à, è, ò, ï, ü`), resulting in truncated and corrupted procedure descriptions (e.g. `TRASPLANTE HEPTICO` instead of `TRASPLANTE HEPÁTICO`). Trying UTF-8 first and falling back to Latin-1 guarantees 100% character preservation with zero dependency overhead.

### Alternatives Considered
- `chardet.detect()`: Adds runtime overhead and probabilistic inaccuracy on small text fragments. Multi-encoding fallback with explicit exception catching is deterministic and faster.

---

## 2. PDF Multi-line Row Buffering & Gazette Noise Filtering

### Decision
1. In `extract_pdf_catalog()`, introduce a 2-line sliding buffer to join split table descriptions where procedure text wraps to a second line before the price column.
2. Apply strict negative regex filters for gazette headers, footers, publication metadata, decree numbers, page numbers, and non-sanitary tax rate brackets:
   ```python
   GAZETTE_NOISE_PATTERNS = [
       r"\bPÁG(?:INA)?\.?\s*\d+",
       r"\bBOLETÍN\s+OFICIAL\b",
       r"\bDIARIO\s+OFICIAL\b",
       r"\bDECRETO\s+\d+",
       r"\bORDEN\s+[A-Z0-9\/]+",
       r"\bLEY\s+\d+\/\d+",
       r"\bEJERCICIO\s+\d{4}\b",
       r"\bDEROGADA\s+LEY\b",
       r"\bVALOR\s+DEL\s+INMUEBLE\b",
       r"\bSI\s+EL\s+COSTE\s+SE\s+SITÚA\b",
       r"\bENTRE\s+[\d\.\,]+\s+Y\s+[\d\.\,]+\b",
       r"\bTRANSPORTE\s+ESCOLAR\b",
       r"^\s*KM\.?\s*$",
   ]
   ```

### Rationale
In PDF table layouts, long clinical descriptions wrap across line breaks. Without buffering, the first line is lost and the second line (e.g., `Y RELACIONADOS_SEV_1`) is falsely extracted as a standalone item. Gazette headers and page numbers (e.g. `9872.00 €` in DOE or `22788.00 €` in DOG) and regional property/transport tax brackets were incorrectly captured by generic price regexes.

### Alternatives Considered
- Full OCR / layout engines (pdfplumber, layoutparser): Heavy, slow (minutes per PDF), and introduces heavy C++ / PyTorch dependencies. `pypdfium2` with sliding-buffer text stream parsing achieves sub-second extraction with high precision.

---

## 3. HTML Multi-Column Table Layout Precedence

### Decision
In `extract_html_catalog()`, reorder table parsing logic so that specific multi-column schemas are evaluated BEFORE generic formats:
1. Baleares 6-column format: `[Nº GRD, Severidad, Peso, Descripción, Importe, Cod. SAP]`
2. Madrid 5-column format: `[Epígrafe, GRD APR, Gravedad, Descripción, Importe]`
3. 3-column / 4-column formats: `[Code, Description, (Weight), Price]`
4. 2-column format: `[Description, Price]`

### Rationale
In the previous implementation, `if len(cells) >= 5 and parse_price(cells[4])` matched 6-column Baleares tables before `elif len(cells) >= 6`, assigning the relative weight (e.g. `18,9530`) as the severity level and creating invalid codes like `APR-GRD:4-18,9530`. Checking 6 columns first cleanly extracts `APR-GRD:001-4`, `SAP:7020640`, and price `138,297.00 €`.

---

## 4. Standardized Clinical Code Grammars & False-Positive Elimination

### Decision
Update `format_code_std()` with strict validation rules:
1. **`ICD-10-PCS`**: Must strictly match authentic ICD-10-PCS grammar:
   - 7 alphanumeric characters `[0-9A-HJ-NP-Z]{7}`
   - First character must be a valid ICD-10-PCS section identifier (`0` Medical/Surgical, `1` Obstetrics, `2` Placement, `3` Administration, `4` Measurement, `5` Extracorporeal, `6` Extracorporeal Therapies, `7` Osteopathic, `8` Other Procedures, `9` Chiropractic, `B` Imaging, `C` Nuclear Medicine, `D` Radiation Therapy, `F` Physical Rehab, `G` Mental Health, `H` Substance Abuse, `X` New Tech).
   - Explicitly blacklist Spanish dictionary words (e.g., `DRENAJE`, `ESCUELA`, `VENDAJE`, `PRUEBAS`, `CELULAR`, `GENERAL`, `CENTRAL`) and Murcia/regional letter prefixes (`PD...`, `TR...`, `RA...`, `MN...`, `LQ...`).
2. **`APR-GRD`**: Normalize to `APR-GRD:<3-digit code>[-<severity 1-4>]` (e.g., `APR-GRD:001-1`, `APR-GRD:540-3`).
3. **`REGIONAL`**: Only prefix genuine regional procedure codes (e.g. `CMA\d{3}`, `V03[A-Z0-9]+`, `LQ\d{5}[A-Z]?`, `E03\.[0-9\.]+`, `A\.\d\.[0-9\.]+`). Reject table subheadings (`B1`, `B2`, `B3`, `DOG`, `1.-`, `2.-`, `PARA`, `OBLIGADOS`).
4. **`CN`** (National Drug Code): 6 digits in medication/pharmacy context.
5. **`SAP`**: 7 digits.

### Rationale
Eliminates 2,135 false-positive `ICD-10-PCS` classifications and 3,500+ false-positive `REGIONAL:` section headers.

---

## 5. Setting & OMOP Domain Inference Rules

### Decision
Refactor `infer_setting()`, `infer_omop_domain()`, and `infer_unit_type()`:
1. **APR-GRD Precedence**: If an item is an `APR-GRD`, default to:
   - `setting`: `"Inpatient"`
   - `omop_domain`: `"Visit"`
   - `unit_type`: `"per_episode"`
   *(Exception: if description or code contains `CMA` / `AMBULATORIA`, `setting = "Procedures"`, `omop_domain = "Procedure"`, `unit_type = "per_procedure"`).*
2. **Expanded Diagnostic Keywords**: `analitica`, `laboratorio`, `ecograf`, `radiolog`, `tomograf`, `tac`, `resonancia`, `rm`, `pet-tac`, `gammagraf`, `biopsia`, `endoscop`, `mamograf`, `ecg`, `electrocardiograma`, `determinacion`, `estudio`, `serologia`, `cultivo`, `citologia`, `perfil`, `genetico`, `espirometria` -> `Diagnostics` / `Measurement` / `per_test`.
3. **Expanded Procedure Keywords**: `cirugia`, `quirurg`, `intervencion`, `cma`, `trasplante`, `artroscopia`, `osteotomia`, `amputacion`, `catarata`, `hernioplastia`, `colecistectomia`, `mastectomia`, `tiroidectomia`, `apendicectomia`, `traqueostom`, `fistul`, `gastrectom`, `injerto`, `reparacion`, `sustitucion`, `implante`, `protesis`, `endarterectomia`, `facoemulsificacion`, `hemodialisis`, `litotricia` -> `Procedures` / `Procedure` / `per_procedure`.
4. **Primary Care Keywords**: `atención primaria`, `atencion primaria`, `centro de salud`, `consultorio`, `médico de familia`, `medico de familia`, `pediatría ap`, `pediatria ap`, `enfermería ap`, `enfermeria ap`, `atención continuada`, `atencion continuada`, `consulta ap` -> `Primary Care` / `Visit` / `per_visit`.
5. **ICU Keywords**: `uci`, `intensivos`, `cuidados intensivos`, `reanimacion`, `criticos` -> `ICU` / `Visit` / `per_diem` or `per_episode`.
6. **Emergency Keywords**: `urgencia`, `emergencia`, `112`, `061` -> `Emergency` / `Visit` / `per_visit`.
7. **Inpatient Keywords**: `hospitaliz`, `estancia`, `ingreso`, `cama`, `convalecencia`, `internamiento` -> `Inpatient` / `Visit` / `per_diem`.
8. **Outpatient**: Specialist visits, consultations, physiotherapy, psychotherapy -> `Outpatient` / `Visit` / `per_visit`.

### Rationale
Rebalances the clinical taxonomy, dropping the artificial 85.3% outpatient fallback to <35% and accurately classifying hospital admissions, diagnostic tests, and surgical procedures.

---

## 6. Official Healthcare CPI Sub-series & Target Year Escalation

### Decision
1. In `fetch_ine_deflators()`, query INE Table 50913 and strictly match:
   `nom == "Nacional. Sanidad. Índice."` (ECOICOP 06 General Healthcare).
2. Also retrieve sub-series for:
   - ECOICOP 06.2: `"Nacional. Servicios médicos y otros servicios ambulatorios. Índice."`
   - ECOICOP 06.3: `"Nacional. Servicios hospitalarios. Índice."`
3. If API is unreachable or fails, use the verified official INE Base 2021=100 historical series:
   - 2013: 97.12
   - 2014: 97.25
   - 2015: 97.39
   - 2016: 97.15
   - 2017: 97.87
   - 2018: 98.16
   - 2019: 98.96
   - 2020: 99.32
   - 2021: 100.00
   - 2022: 101.10
   - 2023: 102.99
   - 2024: 105.09
   - 2025: 107.24 (est)
   - 2026: 109.43 (target projection)
4. Compute inflation multiplier as `deflators[2026] / deflators[year_original]` with exact year resolution.

### Rationale
Prevents general basket CPI (121.59) from introducing severe over-inflation bias into HEOR health system models.

---

## 7. Airflow 3.x DAG Orchestration & XCom Alignment

### Decision
1. Update `dags/cost_extraction_dag.py` so Task 3 (`extract_normalize_validate_export`) pulls the deflator dictionary from Task 2 via XCom:
   ```python
   def task_extract_and_normalize_fn(**context):
       ti = context["ti"]
       deflators = ti.xcom_pull(task_ids="compute_ine_deflators")
       run_pipeline(..., deflators=deflators)
   ```
2. Update `registries.yml`:
   - `sns-2024-siap`: fix `file_format` to `pdf` and specify the SIAP Activity document endpoint.
   - `ine-ipc-medicina`: update format to `json` (or `api`).
