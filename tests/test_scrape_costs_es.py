#!/usr/bin/env python3
"""
tests/test_scrape_costs_es.py - Automated Unit & Integration Tests for HERMES Spanish Cost Pipeline.
"""

import os
import tempfile
import unittest
import pandas as pd

from scripts.download_costs_sources import (
    DEFAULT_SANIDAD_INDICES as DL_DEFAULT_INDICES,
    TARGET_YEAR as DL_TARGET_YEAR,
    download_source,
    export_ine_tables as dl_export_ine,
    fetch_ine_deflators as dl_fetch_ine,
)
from scripts.scrape_costs_es import (
    DEFAULT_SANIDAD_INDICES,
    TARGET_YEAR,
    export_ine_tables,
    extract_source_records,
    fetch_ine_deflators,
    format_code_std,
    infer_omop_domain,
    infer_setting,
    infer_unit_type,
    is_noise_text,
    parse_price,
    read_text_file,
    run_pipeline,
)


class TestScrapeCostsEs(unittest.TestCase):

    def test_read_text_file_encoding(self):
        """Verify multi-encoding fallback correctly decodes UTF-8 and ISO-8859-1 with accents."""
        with tempfile.NamedTemporaryFile("wb", suffix=".html", delete=False) as f:
            f.write("Trasplante hepático y/o de intestino en Cataluña".encode("iso-8859-1"))
            latin1_path = f.name

        try:
            content = read_text_file(latin1_path)
            self.assertIn("hepático", content)
            self.assertIn("Cataluña", content)
        finally:
            os.remove(latin1_path)

    def test_fetch_ine_deflators_sanidad_index(self):
        """Verify deflator series uses ECOICOP 06 Sanidad and excludes General CPI."""
        deflators = fetch_ine_deflators()
        self.assertIn(2021, deflators)
        self.assertEqual(deflators[2021], 100.00)
        self.assertEqual(deflators[TARGET_YEAR], 109.43)
        self.assertEqual(deflators[2024], 105.09)
        self.assertEqual(deflators[2013], 97.12)

        ratio_2024 = deflators[TARGET_YEAR] / deflators[2024]
        self.assertTrue(1.03 < ratio_2024 < 1.05)

    def test_export_ine_tables(self):
        """Verify canonical INE index datasets are correctly exported across formats."""
        with tempfile.TemporaryDirectory() as tmpdir:
            df_ine = export_ine_tables(output_dir=tmpdir)
            self.assertGreaterEqual(len(df_ine), 20)
            self.assertEqual(df_ine["annual_index"].isna().sum(), 0)
            self.assertTrue(os.path.exists(os.path.join(tmpdir, "ine_indices_sanidad.csv")))
            self.assertTrue(os.path.exists(os.path.join(tmpdir, "ine_indices_sanidad.parquet")))
            self.assertTrue(os.path.exists(os.path.join(tmpdir, "ine_indices_sanidad.json")))

    def test_format_code_std_apr_grd(self):
        """Verify APR-GRD code parsing and normalization."""
        self.assertEqual(format_code_std("GRD 001-1"), "APR-GRD:001-1")
        self.assertEqual(format_code_std("APR-GRD:20-2"), "APR-GRD:020-2")
        self.assertEqual(format_code_std("1 G 1"), "APR-GRD:001-1")
        self.assertEqual(format_code_std("540"), "")

    def test_format_code_std_icd_procedures(self):
        """Verify ICD-9 and genuine ICD-10-PCS codes, while rejecting false positive words."""
        self.assertEqual(format_code_std("04.43"), "ICD-9-CM:04.43")
        self.assertEqual(format_code_std("0210093"), "ICD-10-PCS:0210093")
        self.assertEqual(format_code_std("0TT90ZZ"), "ICD-10-PCS:0TT90ZZ")
        self.assertEqual(format_code_std("4A023N7"), "ICD-10-PCS:4A023N7")

        # Reject non-medical Spanish dictionary words and regional acronyms
        self.assertEqual(format_code_std("DRENAJE"), "")
        self.assertEqual(format_code_std("ESCUELA"), "")
        self.assertEqual(format_code_std("VENDAJE"), "")
        self.assertEqual(format_code_std("PRUEBAS"), "")
        self.assertEqual(format_code_std("DESTETE"), "")
        self.assertEqual(format_code_std("FLUTTER"), "")
        self.assertEqual(format_code_std("GCENTMA"), "")

    def test_format_code_std_regional_and_sap(self):
        """Verify genuine regional codes and SAP codes while rejecting section headings."""
        self.assertEqual(format_code_std("CMA001"), "REGIONAL:CMA001")
        self.assertEqual(format_code_std("V03PVC001"), "REGIONAL:V03PVC001")
        self.assertEqual(format_code_std("LQ02166"), "REGIONAL:LQ02166")
        self.assertEqual(format_code_std("PD00002"), "REGIONAL:PD00002")
        self.assertEqual(format_code_std("7020640"), "SAP:7020640")

        # Reject table headers and boilerplate
        self.assertEqual(format_code_std("B1"), "")
        self.assertEqual(format_code_std("B2"), "")
        self.assertEqual(format_code_std("B3"), "")
        self.assertEqual(format_code_std("DOG"), "")
        self.assertEqual(format_code_std("1.-"), "")
        self.assertEqual(format_code_std("PARA"), "")

    def test_is_noise_text(self):
        """Verify negative filtering rejects gazette boilerplate, tax brackets, and page numbers."""
        self.assertTrue(is_noise_text("DE FEBRERO DE 2024"))
        self.assertTrue(is_noise_text("PÁGINA 9872"))
        self.assertTrue(is_noise_text("QUE EL VALOR DEL INMUEBLE TRANSMITIDO NO EXCEDA DE"))
        self.assertTrue(is_noise_text("SI EL COSTE SE SITÚA ENTRE 30.050,62 Y"))
        self.assertTrue(is_noise_text("ENTRE 0 Y 100000"))
        self.assertTrue(is_noise_text("TRANSPORTE ESCOLAR"))
        self.assertTrue(is_noise_text("KM."))
        self.assertTrue(is_noise_text(",67"))

        # Real clinical procedures must NOT be flagged as noise
        self.assertFalse(is_noise_text("CRANEOTOMÍA POR TRAUMA"))
        self.assertFalse(is_noise_text("RESONANCIA MAGNÉTICA CRANEAL"))
        self.assertFalse(is_noise_text("CONSULTA DE ATENCIÓN PRIMARIA"))

    def test_infer_setting_and_omop_domain(self):
        """Verify clinical setting and OMOP domain taxonomy inference."""
        self.assertEqual(infer_setting("CRANEOTOMÍA POR TRAUMA", code_std="APR-GRD:020-1"), "Inpatient")
        self.assertEqual(infer_omop_domain("Inpatient"), "Visit")
        self.assertEqual(infer_unit_type("Inpatient", "CRANEOTOMÍA POR TRAUMA"), "per_episode")

        self.assertEqual(infer_setting("ARTROSCOPIA CMA", code_std="REGIONAL:CMA001"), "Procedures")
        self.assertEqual(infer_omop_domain("Procedures"), "Procedure")
        self.assertEqual(infer_unit_type("Procedures", "ARTROSCOPIA CMA"), "per_procedure")

        self.assertEqual(infer_setting("RESONANCIA MAGNÉTICA NUCLEAR"), "Diagnostics")
        self.assertEqual(infer_omop_domain("Diagnostics"), "Measurement")
        self.assertEqual(infer_unit_type("Diagnostics", "RESONANCIA"), "per_test")

        self.assertEqual(infer_setting("CONSULTA DE MÉDICO DE FAMILIA EN CENTRO DE SALUD"), "Primary Care")
        self.assertEqual(infer_omop_domain("Primary Care"), "Visit")
        self.assertEqual(infer_unit_type("Primary Care", "CONSULTA"), "per_visit")

        # Emergency setting guards & laboratory stat tests
        self.assertEqual(
            infer_setting("G CON ANOMALÍA MAYOR O SIN INTERVENCIÓN DE SOPORTE VITAL (SEVERIDAD 1)"),
            "Inpatient",
        )
        self.assertEqual(infer_setting("BILIRRUBINA [URGENCIAS]", code_std="REGIONAL:LQ08543U"), "Diagnostics")
        self.assertEqual(infer_unit_type("Diagnostics", "BILIRRUBINA [URGENCIAS]"), "per_test")
        self.assertEqual(infer_setting("URGENCIAS HOSPITALARIAS B2 2 5 1 URGENCIAS NO INGRESADAS"), "Emergency")
        self.assertEqual(
            infer_unit_type("Emergency", "TRANSPORTE DE EMERGENCIA ASISTENCIA UVI MÓVIL TERRESTRE"),
            "per_transfer",
        )
        self.assertEqual(
            infer_unit_type("Emergency", "TÉCNICO DE EMERGENCIAS JORNADA ORDINARIA"),
            "per_session",
        )

    def test_bench_05_emergency_dispersion(self):
        """Verify BENCH-05 Emergency Department Episode has CV < 0.80 and realistic ranges."""
        df = pd.read_parquet("data/costs_spain.parquet")
        b5_filter = (
            (df["setting"] == "Emergency")
            & (df["unit_type"] == "per_visit")
            & (df["description"].str.contains(r"\b(?:urgencia|urgencias)\b", case=False, na=False))
            & (
                ~df["description"].str.contains(
                    r"ambulancia|uvi|móvil|movil|traslado|transporte|helicóptero|helicoptero|técnico|tecnico|guardia|analítica|analitica|laboratorio",
                    case=False,
                    na=False,
                )
            )
        )
        b5_df = df[b5_filter]
        self.assertGreater(len(b5_df), 30)
        cv = b5_df["cost_updated"].std() / b5_df["cost_updated"].mean()
        self.assertLess(cv, 0.80)
        self.assertGreater(b5_df["cost_updated"].mean(), 100.0)
        self.assertLess(b5_df["cost_updated"].mean(), 400.0)

        # Verify Andalusia values
        and_b5 = b5_df[b5_df["ccaa"] == "Andalucía"]
        self.assertGreaterEqual(len(and_b5), 2)
        self.assertLess(and_b5["cost_updated"].max(), 600.0)

    def test_canonical_catalog_invariants(self):
        """Verify canonical parquet output satisfies all production quality invariants."""
        parquet_path = "data/costs_spain.parquet"
        self.assertTrue(os.path.exists(parquet_path), "Catalog parquet file must exist")

        df = pd.read_parquet(parquet_path)
        self.assertGreater(len(df), 30000)

        # 1. Zero nulls
        self.assertEqual(df.isna().sum().sum(), 0)

        # 2. Unique cost_id
        self.assertTrue(df["cost_id"].is_unique)

        # 3. Valid price ranges
        self.assertTrue((df["cost_original"] > 0).all())
        self.assertTrue((df["cost_updated"] > 0).all())
        self.assertLess(df["cost_original"].max(), 250000.0)

        # 4. Zero corrupted Balearic APR-GRD codes
        bad_bal = df[df["code_std"].str.contains(r"APR-GRD:\d+-\d+,\d+")]
        self.assertEqual(len(bad_bal), 0)

        # 5. Zero false positive ICD-10-PCS words
        bad_pcs = df[df["code_std"].str.startswith("ICD-10-PCS:DRENAJE")]
        self.assertEqual(len(bad_pcs), 0)

        # 6. Rebalanced settings (Inpatient and Diagnostics accurately populated)
        self.assertGreater((df["setting"] == "Inpatient").sum(), 5000)
        self.assertGreater((df["setting"] == "Diagnostics").sum(), 4000)
        self.assertLess((df["setting"] == "Outpatient").mean(), 0.65)

    def test_downloader_and_offline_scraper_split(self):
        """Verify dedicated downloader module and 100% offline scraper extraction."""
        # Check downloader module symbols
        self.assertEqual(DL_TARGET_YEAR, TARGET_YEAR)
        self.assertEqual(DL_DEFAULT_INDICES[2021], DEFAULT_SANIDAD_INDICES[2021])

        # Test single-source offline extraction
        sample_src = {
            "id": "and-2024-precios",
            "ccaa": "Andalucía",
            "year": 2024,
            "file_format": "pdf",
            "legal_title": "Tarifas SAS 2024",
            "url_pdf": "",
        }
        raw_file = "data/raw/and-2024-precios.pdf"
        if os.path.exists(raw_file):
            records = extract_source_records(sample_src, raw_file)
            self.assertGreater(len(records), 1000)
            self.assertEqual(records[0].ccaa, "Andalucía")

        # Test run_pipeline single source offline preview
        if os.path.exists(raw_file):
            df_preview, _ = run_pipeline(
                registry_path="data/specs/registries.yml",
                raw_dir="data/raw",
                source_id="and-2024-precios",
                limit_preview=5,
            )
            self.assertEqual(len(df_preview), 5)
            self.assertEqual(df_preview["ccaa"].iloc[0], "Andalucía")


if __name__ == "__main__":
    unittest.main()
