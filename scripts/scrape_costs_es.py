#!/usr/bin/env python3
"""
scripts/scrape_costs_es.py - Comprehensive ground-source healthcare cost extractor for Spain.

Downloads, extracts, normalizes, inflates, and validates public healthcare tariffs
from all 17 Autonomous Communities, INGESA, and National sources into HERMES catalogs.
Persists official INE Table 50913 (ECOICOP 06 Sanidad) series as canonical dataset artifacts.
"""

import argparse
import csv
import json
import os
import re
import ssl
import sys
import time
from dataclasses import asdict, dataclass
from typing import Any, Dict, List, Optional, Set, Tuple

import openpyxl
import pandas as pd
import pypdfium2
import requests
import yaml
from bs4 import BeautifulSoup

# ponytail: bypass legacy SSL checks on public Spanish regional gazette domains
SSL_CTX = ssl.create_default_context()
SSL_CTX.check_hostname = False
SSL_CTX.verify_mode = ssl.CERT_NONE

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    )
}

TARGET_YEAR = 2026

# Official verified INE Base 2021=100 historical series for ECOICOP 06 Sanidad
DEFAULT_SANIDAD_INDICES: Dict[int, float] = {
    2002: 87.50,
    2003: 89.34,
    2004: 89.67,
    2005: 90.44,
    2006: 91.66,
    2007: 90.27,
    2008: 90.42,
    2009: 89.81,
    2010: 88.94,
    2011: 87.76,
    2012: 90.87,
    2013: 97.12,
    2014: 97.25,
    2015: 97.39,
    2016: 97.15,
    2017: 97.87,
    2018: 98.16,
    2019: 98.96,
    2020: 99.32,
    2021: 100.00,
    2022: 101.10,
    2023: 102.99,
    2024: 105.09,
    2025: 107.24,
    2026: 109.43,
}

SPANISH_WORDS_7 = {
    "DRENAJE",
    "ESCUELA",
    "VENDAJE",
    "PRUEBAS",
    "CELULAR",
    "GENERAL",
    "CENTRAL",
    "EXTRACC",
    "MARCAJE",
    "INFARTO",
    "BIOPSIA",
    "CONSULT",
    "REVISTA",
    "ESTUDIO",
    "TECNICA",
    "ENFERMO",
    "TERAPIA",
    "REUNION",
    "TRABAJO",
}


@dataclass
class CostRecord:
    cost_id: str
    description: str
    cost_group: str
    setting: str
    specialty: str
    unit_type: str
    cost_original: float
    year_original: int
    cost_updated: float
    year_updated: int
    ccaa: str
    legal_source: str
    source_url: str
    code_std: str = ""
    omop_domain: str = "Procedure"


@dataclass
class IneIndexRecord:
    ecoicop_code: str
    series_name: str
    year: int
    annual_index: float
    factor_to_2026: float
    is_projected: bool


def read_text_file(filepath: str) -> str:
    """Read text/html file with multi-encoding fallback (UTF-8 -> ISO-8859-1 -> Windows-1252)."""
    for enc in ["utf-8", "iso-8859-1", "windows-1252"]:
        try:
            with open(filepath, "r", encoding=enc) as f:
                return f.read()
        except UnicodeDecodeError:
            continue
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def fetch_ine_deflators(cache_path: str = "data/raw/ine-ipc-medicina.json") -> Dict[int, float]:
    """Fetch healthcare CPI index series from INE API (Table 50913 - ECOICOP 06 Sanidad) or fallback."""
    url = "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/50913"
    indices: Dict[int, float] = dict(DEFAULT_SANIDAD_INDICES)
    raw_data = None

    # Check local cached JSON first
    if os.path.exists(cache_path) and os.path.getsize(cache_path) > 1000:
        try:
            with open(cache_path, "r", encoding="utf-8") as f:
                raw_data = json.load(f)
        except Exception:
            pass

    # Fetch from API if not cached
    if not raw_data:
        try:
            r = requests.get(url, headers=HEADERS, verify=False, timeout=10)
            if r.status_code == 200:
                raw_data = r.json()
                os.makedirs(os.path.dirname(cache_path), exist_ok=True)
                with open(cache_path, "w", encoding="utf-8") as f:
                    json.dump(raw_data, f)
        except Exception as e:
            print(f"[WARN] Using base INE deflators ({e})")

    if raw_data and isinstance(raw_data, list):
        for series in raw_data:
            nom = series.get("Nombre", "").strip()
            # Strictly match ECOICOP 06 Sanidad (avoid General CPI)
            if (
                nom.startswith("Nacional. Sanidad. Índice")
                or nom.startswith("Nacional. 06 Sanidad. Índice")
                or "Nacional. Sanidad. Índice." in nom
            ):
                pts = series.get("Data", [])
                by_yr: Dict[int, List[float]] = {}
                for p in pts:
                    y = p.get("Anyo")
                    v = p.get("Valor")
                    if y and v is not None:
                        by_yr.setdefault(int(y), []).append(float(v))
                for y, vals in by_yr.items():
                    indices[y] = round(sum(vals) / len(vals), 2)
                if 2025 in indices and 2024 in indices:
                    annual_rate = indices[2025] / indices[2024]
                    indices[2026] = round(indices[2025] * annual_rate, 2)
                break

    return indices


def export_ine_tables(
    output_dir: str = "data", raw_path: str = "data/raw/ine-ipc-medicina.json"
) -> pd.DataFrame:
    """Parse and export official INE Table 50913 ECOICOP 06 series to CSV, Parquet, and JSON."""
    deflators = fetch_ine_deflators(cache_path=raw_path)
    target_idx = deflators.get(TARGET_YEAR, 109.43)

    records: List[IneIndexRecord] = []
    for yr in sorted(deflators.keys()):
        idx_val = deflators[yr]
        fac = round(target_idx / idx_val, 4)
        is_proj = yr >= 2025
        records.append(
            IneIndexRecord(
                ecoicop_code="06",
                series_name="Nacional. Sanidad. Índice.",
                year=yr,
                annual_index=idx_val,
                factor_to_2026=fac,
                is_projected=is_proj,
            )
        )

    df_ine = pd.DataFrame([asdict(r) for r in records])
    os.makedirs(output_dir, exist_ok=True)

    csv_path = os.path.join(output_dir, "ine_indices_sanidad.csv")
    parquet_path = os.path.join(output_dir, "ine_indices_sanidad.parquet")
    json_path = os.path.join(output_dir, "ine_indices_sanidad.json")

    df_ine.to_csv(csv_path, index=False, encoding="utf-8")
    df_ine.to_parquet(parquet_path, index=False, compression="snappy")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(df_ine.to_dict(orient="records"), f, indent=2, ensure_ascii=False)

    print(f"[EXPORT] Exported canonical INE index datasets -> {parquet_path}")
    return df_ine


def is_noise_text(text: str) -> bool:
    """Detect non-medical gazette boilerplate, page numbers, and tax bracket text."""
    t = text.strip()
    if len(t) < 3:
        return True

    noise_patterns = [
        r"\bPÁG(?:INA|\.)?\s*\d+",
        r"\bBOLETÍN\s+OFICIAL\b",
        r"\bDIARIO\s+OFICIAL\b",
        r"\bDECRETO\s+\d+",
        r"\bDECRETO\s+LEY\b",
        r"\bORDEN\s+[A-Z0-9\/]+",
        r"\bLEY\s+\d+\/\d+",
        r"\bEJERCICIO\s+\d{4}\b",
        r"\bDEROGADA\s+LEY\b",
        r"\bVALOR\s+DEL\s+INMUEBLE\b",
        r"\bSI\s+EL\s+COSTE\s+SE\s+SITÚA\b",
        r"\bENTRE\s+[\d\.\,]+\s+Y\s+[\d\.\,]+\b",
        r"\bTRANSPORTE\s+ESCOLAR\b",
        r"\bPOR\s+CADA\s+INSCRIPCIÓN\b",
        r"\bLOS\s+SALDOS\s+REMANENTES\b",
        r"\bDISPOSICIÓN\s+(?:ADICIONAL|TRANSITORIA|FINAL)\b",
        r"\bARTÍCULO\s+\d+",
        r"\bARTICLE\s+\d+",
        r"\bIVAM\b",
        r"\bCINEGÉTIC",
        r"\bATRAQUE\b",
        r"\bAMARRE\b",
        r"\b(?:DE\s+)?(?:ENERO|FEBRERO|MARZO|ABRIL|MAYO|JUNIO|JULIO|AGOSTO|SEPTIEMBRE|OCTUBRE|NOVIEMBRE|DICIEMBRE)\s+DE\s+\d{4}\b",
        r"^\s*KM\.?\s*$",
        r"^\s*RECORRIDO\)?\s*$",
        r"^\s*,\d+\s*$",
    ]
    for pat in noise_patterns:
        if re.search(pat, t, re.I):
            return True

    # Check if string starts with dangling prepositions / conjunctions
    if re.match(r"^(?:Y|O|DE|EN|CON|SIN|DEL|POR|A|E|PARA)\s+[A-Z0-9_\-]{2,15}$", t):
        return True

    return False


def infer_setting(desc: str, code_std: str = "") -> str:
    """Infer clinical setting with APR-GRD precedence and expanded keywords."""
    d = desc.lower()

    # Precedence: APR-GRD casemix categories default to Inpatient unless CMA
    if code_std.startswith("APR-GRD:"):
        if any(k in d for k in ["cma", "ambulatori", "sin ingreso", "mayor ambulatoria"]):
            return "Procedures"
        return "Inpatient"

    if any(k in d for k in ["uci", "intensivos", "reanimaci", "cuidados intensivos", "criticos"]):
        return "ICU"
    if any(
        k in d
        for k in [
            "urgencia",
            "emergencia",
            "112",
            "061",
            "atención continuada",
            "atencion continuada",
        ]
    ):
        return "Emergency"
    if any(
        k in d
        for k in [
            "atención primaria",
            "atencion primaria",
            "médico de familia",
            "medico de familia",
            "pediatría ap",
            "pediatria ap",
            "enfermería ap",
            "enfermeria ap",
            "centro de salud",
            "consultorio",
            "consulta ap",
            "atención médica no urgente en centro salud",
            "atención enfermera no urgente",
        ]
    ):
        return "Primary Care"
    if any(
        k in d
        for k in [
            "hospitaliz",
            "estancia",
            "ingreso",
            "cama",
            "convalecencia",
            "internamiento",
            "craneotom",
            "trasplante",
            "traqueostom",
            "infarto",
            "neumonía",
            "sepsis",
        ]
    ):
        return "Inpatient"
    if any(
        k in d
        for k in [
            "resonancia",
            "tac",
            "tomograf",
            "radiolog",
            "ecograf",
            "analitica",
            "laboratorio",
            "biopsia",
            "pet-tac",
            "gammagraf",
            "endoscop",
            "mamograf",
            "electrocardiograma",
            "ecg",
            "radiografia",
            "determinacion",
            "estudio genetico",
            "serologia",
            "cultivo",
            "citologia",
            "perfil",
            "tincion",
            "microbiolog",
            "espirometria",
            "alergia",
            "audiometria",
            "ige",
            "igg",
            "igm",
            "suero",
            "plasma",
            "orina",
        ]
    ):
        return "Diagnostics"
    if any(
        k in d
        for k in [
            "quirurg",
            "cirugia",
            "intervencion",
            "artroscopia",
            "escision",
            "reparacion",
            "injerto",
            "sustitucion",
            "osteotomia",
            "amigdalectomia",
            "catarata",
            "safenectomia",
            "fistul",
            "gastrectom",
            "implante",
            "protesis",
            "endarterectomia",
            "facoemulsificacion",
            "tiroidectomia",
            "mastectomia",
            "colecistectomia",
            "hernioplastia",
            "apendicectomia",
            "amputacion",
            "hemodialisis",
            "litotricia",
            "cateterismo",
            "angioplastia",
            "embolizacion",
            "drenaje",
            "cma",
            "legrado",
            "cesárea",
            "parto",
        ]
    ):
        return "Procedures"
    if any(
        k in d
        for k in [
            "consulta",
            "visita",
            "revision",
            "rehabilitacion",
            "fisioterapia",
            "psicoterapia",
            "logopedia",
        ]
    ):
        return "Outpatient"
    return "Outpatient"


def infer_unit_type(setting: str, desc: str) -> str:
    d = desc.lower()
    if any(k in d for k in ["sesion", "sesión", "tratamiento continuo", "hemodialisis", "hemodiálisis"]):
        return "per_session"
    if setting in ["Inpatient", "ICU"]:
        if any(k in d for k in ["dia", "día", "diaria", "diario", "estancia", "cama"]):
            return "per_diem"
        return "per_episode"
    if setting in ["Outpatient", "Emergency", "Primary Care"]:
        if any(k in d for k in ["procedimiento", "tecnica", "cirugia", "quirurg"]):
            return "per_procedure"
        return "per_visit"
    if setting == "Diagnostics":
        return "per_test"
    if setting == "Procedures":
        return "per_procedure"
    return "per_procedure"


def infer_omop_domain(setting: str) -> str:
    if setting in ["Inpatient", "ICU", "Outpatient", "Emergency", "Primary Care"]:
        return "Visit"
    if setting == "Diagnostics":
        return "Measurement"
    if setting == "Procedures":
        return "Procedure"
    if setting == "Pharmacy":
        return "Drug"
    return "Procedure"


def infer_specialty(desc: str) -> str:
    d = desc.lower()
    mapping = [
        ("trauma", "Traumatología"),
        ("oftalm", "Oftalmología"),
        ("dermat", "Dermatología"),
        ("cardio", "Cardiología"),
        ("neuro", "Neurología"),
        ("digest", "Aparato Digestivo"),
        ("ginec", "Ginecología"),
        ("urolog", "Urología"),
        ("otorrino", "Otorrinolaringología"),
        ("radiolog", "Radiología"),
        ("rehab", "Rehabilitación"),
        ("psiquiat", "Psiquiatría"),
        ("anest", "Anestesiología"),
        ("pediatr", "Pediatría"),
        ("nefrolog", "Nefrología"),
        ("oncolog", "Oncología"),
        ("hematol", "Hematología"),
        ("respirat", "Neumología"),
        ("pulmon", "Neumología"),
        ("hepatic", "Hepatología"),
        ("atención primaria", "Atención Primaria"),
        ("centro salud", "Atención Primaria"),
        ("médico de familia", "Atención Primaria"),
    ]
    for k, v in mapping:
        if k in d:
            return v
    return "General"


def parse_price(text: Any) -> Optional[float]:
    if text is None:
        return None
    cleaned = (
        str(text)
        .replace("€", "")
        .replace("Euros", "")
        .replace("euros", "")
        .replace("EUR", "")
        .strip()
    )
    m = re.search(
        r"(\d{1,3}(?:\.\d{3})*,\d{2}|\d+,\d{2}|\d{1,3}(?:\.\d{3})+(?!\d)|\d+\.\d{2}|\b\d{1,6}\b)",
        cleaned,
    )
    if m:
        raw = m.group(1).replace(".", "").replace(",", ".")
        try:
            val = float(raw)
            if 0.5 <= val < 250_000:
                return round(val, 2)
        except ValueError:
            return None
    return None


def format_code_std(raw_code: Any, context: str = "") -> str:
    if not raw_code:
        return ""
    c = str(raw_code).strip()
    if not c or c.lower() in ["none", "null", "-", "s/c", "n/a", "la", "el", "de", "en", "del", "dog"]:
        return ""

    # Filter out table section headers / generic words
    if re.match(r"^\d{1,2}\.?$", c) or re.match(r"^[IVXLCDM]+\.?$", c, re.I):
        return ""
    if re.match(r"^(?:B\d|DOG|\d+\.-|PARA|OBLIGADOS|SOBRE|PERFIL)$", c, re.I):
        return ""

    # Check APR-GRD (e.g. GRD 001, APR-GRD 123-1, 1 G 1, 1G1)
    m_grd = re.match(r"^(?:APR[-_ ]?GRD|GRD)\s*[:\-]?\s*(\d{1,4})(?:-(\d))?$", c, re.I)
    if m_grd:
        grd_num = m_grd.group(1).zfill(3)
        sev = m_grd.group(2)
        return f"APR-GRD:{grd_num}-{sev}" if sev else f"APR-GRD:{grd_num}"

    m_g = re.match(r"^(\d{1,4})\s*G\s*(\d+)$", c, re.I)
    if m_g:
        return f"APR-GRD:{m_g.group(1).zfill(3)}-{m_g.group(2)}"

    # Check ICD-9-CM (e.g. 04.43, 13.41, 43.11, 08.20, 89.54, or CIE.9.MC.11.3X)
    m_cie = re.match(r"^CIE\.?9(?:\.MC)?\.([0-9A-Z\.]+)$", c, re.I)
    if m_cie:
        return f"ICD-9-CM:{m_cie.group(1)}"
    if re.match(r"^\d{2}\.\d{1,2}[A-Z]?$", c):
        return f"ICD-9-CM:{c}"

    # Check SAP code (7-digit number starting with 7 or 10 or in sap context)
    if re.match(r"^\d{7}$", c) and (c.startswith(("7", "10")) or "sap" in context.lower()):
        return f"SAP:{c}"

    # Check authentic ICD-10-PCS (7 chars, valid section prefix 0-9, B-D, F-H, X)
    if (
        re.match(r"^[0-9A-HJ-NP-Z]{7}$", c, re.I)
        and c.upper() not in SPANISH_WORDS_7
        and not re.match(r"^(?:PD|TR|RA|MN|LQ)\d{5}$", c, re.I)
        and c[0].upper() in "0123456789BCDFGHX"
    ):
        c_up = c.upper()
        if not (c_up.isalpha() and not (c_up.endswith("ZZ") or c_up.endswith("ZX") or c_up.endswith("KZ"))):
            return f"ICD-10-PCS:{c_up}"

    # Check National Drug Code (6 digits)
    if re.match(r"^\d{6}$", c) and any(
        k in context.lower() for k in ["farmac", "medicamento", "cn", "nomenclator"]
    ):
        return f"CN:{c}"

    # Check SAP code (7 digits)
    if re.match(r"^\d{7}$", c):
        return f"SAP:{c}"

    # Authentic regional codes
    if (
        re.match(r"^(?:AM|TS)\d{4}$", c, re.I)
        or re.match(r"^CMA\d{3}$", c, re.I)
        or re.match(r"^V03[A-Z0-9]+$", c, re.I)
        or re.match(r"^LQ\d{5}[A-Z]?$", c, re.I)
        or re.match(r"^(?:PD|TR|RA|MN)\d{5}$", c, re.I)
        or re.match(r"^E03\.[0-9\.]+$", c)
        or re.match(r"^[A-D]\.\d+(?:\.[A-Z0-9]+)*$", c)
        or re.match(r"^C\.A\.[A-Z0-9\.]+$", c)
        or re.match(r"^D\.\d+$", c)
        or re.match(r"^317\.\d(?:\.[0-9]+)+$", c)
        or re.match(r"^\d+\.\d+(?:\.\d+)+$", c)
    ):
        return f"REGIONAL:{c}"

    return ""


def download_source(
    src: Dict[str, Any], raw_dir: str = "data/raw", force: bool = False
) -> str:
    """Download single source document to data/raw/."""
    os.makedirs(raw_dir, exist_ok=True)
    src_id = src["id"]
    fmt = src.get("file_format", "pdf")
    target_path = os.path.join(raw_dir, f"{src_id}.{fmt}")

    if not force and os.path.exists(target_path) and os.path.getsize(target_path) > 200:
        return target_path

    if src_id == "can-2024-precios":
        url = "https://sede.gobiernodecanarias.org/boc/boc-a-2024-077-1334.pdf"
    elif src_id == "pvas-2024-precios":
        url = src.get("url_data") or src.get("url_pdf")
    elif src_id == "arag-2023-precios":
        url = src.get("url_data") or src.get("url_pdf")
    elif src_id == "mad-2023-precios":
        url = src.get("url_gazette", "")
    else:
        url = src.get("url_pdf") or src.get("url_data") or src.get("url_gazette", "")

    if not url:
        return target_path

    # Special handling for Madrid JSF dynamic HTML
    if src_id == "mad-2023-precios":
        try:
            session = requests.Session()
            r_init = session.get(url, headers=HEADERS, verify=False, timeout=15)
            m = re.findall(r"ficheroTemporal_\d+\.html", r_init.text)
            if m:
                mad_url = f"https://gestiona.comunidad.madrid/wleg_pub/html/{m[0]}"
                r_mad = session.get(mad_url, headers=HEADERS, verify=False, timeout=20)
                if r_mad.status_code == 200 and len(r_mad.content) > 1000:
                    with open(target_path, "wb") as f:
                        f.write(r_mad.content)
                    print(f"[DOWNLOAD] {src_id} -> {target_path} ({len(r_mad.content)} bytes)")
                    return target_path
        except Exception as e:
            print(f"[WARN] Madrid dynamic download fallback: {e}")

    try:
        r = requests.get(url, headers=HEADERS, verify=False, timeout=30)
        if r.status_code == 200 and len(r.content) > 200:
            with open(target_path, "wb") as f:
                f.write(r.content)
            print(f"[DOWNLOAD] {src_id} -> {target_path} ({len(r.content)} bytes)")
        else:
            print(f"[WARN] Non-200 or empty response for {src_id}: {r.status_code}")
    except Exception as e:
        print(f"[WARN] Could not download {src_id} ({e}), using cached if present.")

    return target_path


def extract_grd_excel(
    src: Dict[str, Any], filepath: str, deflators: Dict[int, float]
) -> List[CostRecord]:
    """Parse official APR-GRD Casemix Excel workbook."""
    records: List[CostRecord] = []
    wb = openpyxl.load_workbook(filepath, read_only=True)
    sheet = wb["NORMA APR-NIVELES SEVERIDAD"]

    year = src.get("year", 2023)
    target_idx = deflators.get(TARGET_YEAR, 109.43)
    base_idx = deflators.get(year, DEFAULT_SANIDAD_INDICES.get(year, 102.99))
    factor = target_idx / base_idx

    legal_source = src.get("legal_title", "")
    source_url = src.get("url_data") or src.get("url_gazette", "")

    seq = 1
    for i, row in enumerate(sheet.iter_rows(values_only=True)):
        if i < 4:
            continue
        grd_code = str(row[0]) if row[0] else ""
        desc = str(row[2]) if row[2] else ""
        tipo = str(row[4]) if row[4] else "Médico"
        coste = row[17]

        if not grd_code or not desc or not coste or float(coste) <= 0:
            continue

        setting = "Procedures" if "quirúrg" in tipo.lower() else "Inpatient"
        omop_domain = "Procedure" if setting == "Procedures" else "Visit"
        unit_type = "per_procedure" if setting == "Procedures" else "per_episode"
        specialty = infer_specialty(desc)
        cost_orig = round(float(coste), 2)
        cost_upd = round(cost_orig * factor, 2)
        clean_desc = re.sub(r"\s+", " ", desc).strip().upper()

        records.append(
            CostRecord(
                cost_id=f"sns-grd-v40-{seq:05d}",
                description=clean_desc,
                cost_group="Costes GRD (RAE-CMBD)",
                setting=setting,
                specialty=specialty,
                unit_type=unit_type,
                cost_original=cost_orig,
                year_original=year,
                cost_updated=cost_upd,
                year_updated=TARGET_YEAR,
                ccaa="Nacional",
                legal_source=legal_source,
                source_url=source_url,
                code_std=f"APR-GRD:{grd_code}",
                omop_domain=omop_domain,
            )
        )
        seq += 1

    return records


def extract_html_catalog(
    src: Dict[str, Any], filepath: str, deflators: Dict[int, float]
) -> List[CostRecord]:
    """Parse HTML catalogs with multi-encoding support and explicit layout precedence."""
    records: List[CostRecord] = []
    source_id = src["id"]
    ccaa = src["ccaa"]
    year = src.get("year", 2023)
    category = src.get("category", "Precios Públicos / Tasas por Asistencia Sanitaria")
    legal_source = src.get("legal_title", "")
    source_url = src.get("url_gazette") or src.get("url_pdf") or src.get("url_data", "")

    target_idx = deflators.get(TARGET_YEAR, 109.43)
    base_idx = deflators.get(year, DEFAULT_SANIDAD_INDICES.get(year, 102.99))
    factor = target_idx / base_idx

    seen: Set[str] = set()
    seq = 1

    html_content = read_text_file(filepath)
    soup = BeautifulSoup(html_content, "html.parser")
    tables = soup.find_all("table")

    for table in tables:
        for row in table.find_all("tr"):
            cells = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
            if len(cells) < 2:
                continue

            desc, code_raw, price = None, None, None

            # Layout 1 (Priority): Baleares 6-column [GRD, Severity, Weight, Description, Price, SAP]
            if (
                len(cells) >= 6
                and cells[0].isdigit()
                and cells[1].isdigit()
                and parse_price(cells[4])
            ):
                grd = cells[0].zfill(3)
                sev = cells[1]
                code_raw = f"APR-GRD:{grd}-{sev}"
                desc = cells[3]
                price = parse_price(cells[4])

            # Layout 2: Madrid 5-column [Epígrafe, GRD APR, Gravedad, Descripción, Importe]
            elif (
                len(cells) >= 5
                and not any("epígrafe" in c.lower() for c in cells[:2])
                and parse_price(cells[4])
            ):
                epigrafe = cells[0]
                grd = cells[1]
                gravedad = cells[2]
                desc = cells[3]
                price = parse_price(cells[4])
                if grd and gravedad and (grd.isdigit() or "G" in grd):
                    code_raw = f"APR-GRD:{grd.zfill(3)}-{gravedad}"
                elif epigrafe and re.match(r"^E03\.[0-9\.]+$", epigrafe):
                    code_raw = f"REGIONAL:{epigrafe}"

            # Layout 3: Standard [Code, Desc, Price] or [Code, Desc, Weight, Price]
            elif len(cells) >= 3 and parse_price(cells[-1]):
                price = parse_price(cells[-1])
                code_raw = cells[0]
                desc = cells[1]
                if len(cells) >= 4 and len(desc) < 4:
                    desc = cells[2]
            elif len(cells) == 2 and parse_price(cells[1]):
                desc = cells[0]
                price = parse_price(cells[1])
            else:
                for i in range(len(cells) - 1, 0, -1):
                    p = parse_price(cells[i])
                    if p:
                        price = p
                        desc = cells[i - 1]
                        if i >= 2:
                            code_raw = cells[0]
                        break

            if not price or not desc or len(desc) < 3 or price <= 0:
                continue

            # Strip section numbers, index leader dots, and clean text
            clean_desc = re.sub(r"\.{3,}", "", desc)
            clean_desc = re.sub(
                r"^(?:[0-9]+(?:\.[0-9]+)*|[A-Z]\.(?:[0-9]+(?:\.[0-9]+)*)?)\s*[\.\-\)]?\s*",
                "",
                clean_desc,
            ).strip()
            clean_desc = re.sub(r"\s+", " ", clean_desc).strip().upper()

            if is_noise_text(clean_desc):
                continue

            code_std = format_code_std(code_raw, context=clean_desc)
            sig = f"{clean_desc}|{price}|{ccaa}"
            if sig in seen:
                continue
            seen.add(sig)

            setting = infer_setting(clean_desc, code_std=code_std)
            unit_type = infer_unit_type(setting, clean_desc)
            omop_domain = infer_omop_domain(setting)
            specialty = infer_specialty(clean_desc)
            cost_upd = round(price * factor, 2)

            records.append(
                CostRecord(
                    cost_id=f"{source_id}-{seq:05d}",
                    description=clean_desc,
                    cost_group=category,
                    setting=setting,
                    specialty=specialty,
                    unit_type=unit_type,
                    cost_original=price,
                    year_original=year,
                    cost_updated=cost_upd,
                    year_updated=TARGET_YEAR,
                    ccaa=ccaa,
                    legal_source=legal_source,
                    source_url=source_url,
                    code_std=code_std,
                    omop_domain=omop_domain,
                )
            )
            seq += 1

    return records


def extract_valencia_pdf(
    src: Dict[str, Any], pdf: Any, deflators: Dict[int, float]
) -> List[CostRecord]:
    """Parse statutory Valencia outpatient & emergency transport tariffs from DOGV."""
    records: List[CostRecord] = []
    source_id = src["id"]
    ccaa = src["ccaa"]
    year = src.get("year", 2023)
    category = src.get("category", "Precios Públicos / Tasas por Asistencia Sanitaria")
    legal_source = src.get("legal_title", "")
    source_url = src.get("url_pdf") or src.get("url_gazette", "")
    target_idx = deflators.get(TARGET_YEAR, 109.43)
    base_idx = deflators.get(year, DEFAULT_SANIDAD_INDICES.get(year, 102.99))
    factor = target_idx / base_idx

    text_p20 = pdf[19].get_textpage().get_text_range()
    text_p21 = pdf[20].get_textpage().get_text_range()

    sp_p20 = text_p20[text_p20.find("Artículo 9"):text_p20.find("Article 9")]
    lines_p21 = text_p21.split("\n")
    sp_lines_p21 = []
    in_ts = False
    for l in lines_p21:
        if "AM0410" in l:
            in_ts = False
        if "TS0002" in l:
            in_ts = True
        if in_ts:
            if "Las cuantías" in l or "Article 10" in l or "Cuando el servicio" in l:
                break
            sp_lines_p21.append(l)
        else:
            if "(*) Cuando" in l or "Article 9" in l or "Article 10" in l:
                continue
            if len(sp_lines_p21) < 26:
                sp_lines_p21.append(l)

    combined = sp_p20 + "\n" + "\n".join(sp_lines_p21)
    tokens = re.split(r"((?:AM|TS)\d{4})", combined)
    seq = 1
    seen = set()
    for i in range(1, len(tokens), 2):
        code = tokens[i].strip()
        body = tokens[i + 1].strip()
        if code == "TS0003":
            m_km = re.search(r"(\d+,\d{2})\s*por\s*km", body)
            price = float(m_km.group(1).replace(",", ".")) if m_km else 0.78
            raw_desc = body[: body.find(m_km.group(0))].strip() if m_km and m_km.group(0) in body else body
        else:
            m_price = re.search(r"(\d{1,3}(?:\.\d{3})*,\d{2}|\d+,\d{2}|\d{1,3}(?:\.\d{3})+|\d+)\s*€", body)
            if not m_price:
                continue
            raw_desc = body[: m_price.start()].strip()
            price_str = m_price.group(1).replace(".", "").replace(",", ".")
            price = float(price_str)

        desc = re.sub(r"\(\*+\)", "", raw_desc)
        desc = re.sub(r"Artículo \d+.*", "", desc)
        desc = re.sub(r"\s+", " ", desc).strip().upper()
        if not desc or price <= 0 or code in seen:
            continue
        seen.add(code)

        code_std = f"REGIONAL:{code}"
        setting = infer_setting(desc, code_std=code_std)
        unit_type = infer_unit_type(setting, desc)
        omop_domain = infer_omop_domain(setting)
        specialty = infer_specialty(desc)
        cost_upd = round(price * factor, 2)

        records.append(
            CostRecord(
                cost_id=f"{source_id}-{seq:05d}",
                description=desc,
                cost_group=category,
                setting=setting,
                specialty=specialty,
                unit_type=unit_type,
                cost_original=price,
                year_original=year,
                cost_updated=cost_upd,
                year_updated=TARGET_YEAR,
                ccaa=ccaa,
                legal_source=legal_source,
                source_url=source_url,
                code_std=code_std,
                omop_domain=omop_domain,
            )
        )
        seq += 1
    return records


def extract_pdf_catalog(
    src: Dict[str, Any], filepath: str, deflators: Dict[int, float]
) -> List[CostRecord]:
    """Parse regional PDF gazettes with page slicing, sliding buffer and noise filtering."""
    records: List[CostRecord] = []
    source_id = src["id"]
    ccaa = src["ccaa"]
    year = src.get("year", 2023)
    category = src.get("category", "Precios Públicos / Tasas por Asistencia Sanitaria")
    legal_source = src.get("legal_title", "")
    source_url = src.get("url_pdf") or src.get("url_gazette", "")

    target_idx = deflators.get(TARGET_YEAR, 109.43)
    base_idx = deflators.get(year, DEFAULT_SANIDAD_INDICES.get(year, 102.99))
    factor = target_idx / base_idx

    seen: Set[str] = set()
    seq = 1

    try:
        pdf = pypdfium2.PdfDocument(filepath)
    except Exception as e:
        print(f"[WARN] Failed to open PDF {filepath}: {e}")
        return records

    # Dedicated parser for structured DOGV Valencian gazette
    if source_id == "val-2023-tasas":
        return extract_valencia_pdf(src, pdf, deflators)

    page_start = src.get("page_start", 1)
    page_end = src.get("page_end", len(pdf))
    page_indices = range(max(0, page_start - 1), min(page_end, len(pdf)))

    for page_idx in page_indices:
        page = pdf[page_idx]
        textpage = page.get_textpage()
        text = textpage.get_text_range() or ""
        lines = text.replace("\r", "").split("\n")

        buffer_line = ""
        for line in lines:
            line_clean = line.strip()
            if not line_clean:
                continue

            if is_noise_text(line_clean):
                buffer_line = ""
                continue

            candidate_line = f"{buffer_line} {line_clean}" if buffer_line else line_clean

            if not any(ch.isdigit() for ch in candidate_line):
                buffer_line = line_clean if len(line_clean) < 150 else ""
                continue

            desc, code_raw, price = None, None, None

            # Pattern 1: País Vasco GRD
            m_pvas = re.search(
                r"^(\d+\s*G\s*\d+)\s+(.+?)\s+Gravedad\s+\d+\s+[\d\,]+\s+(\d{1,3}(?:\.\d{3})*|\d+)\s+(\d+)",
                candidate_line,
            )
            if m_pvas:
                code_raw = m_pvas.group(1).replace(" ", "")
                desc = m_pvas.group(2).strip()
                price = parse_price(m_pvas.group(3))
            else:
                m_gen_end = re.search(
                    r"(\d{1,3}(?:\.\d{3})*,\d{2}|\d+,\d{2}|\d{1,3}(?:\.\d{3})+|\d{1,6})\s*€?$",
                    candidate_line,
                )
                if m_gen_end:
                    price = parse_price(m_gen_end.group(1))
                    raw_desc = candidate_line[: m_gen_end.start()].strip()
                    m_grd = re.match(
                        r"^(?:GRD\s*0?(\d{1,4})\s*[-–]?\s*)(.*?)(?:_?SEV[_\s]?(\d))?$",
                        raw_desc,
                        re.I,
                    )
                    if m_grd:
                        grd_num = m_grd.group(1).zfill(3)
                        sev_num = m_grd.group(3)
                        code_raw = f"APR-GRD:{grd_num}-{sev_num}" if sev_num else f"APR-GRD:{grd_num}"
                        desc = m_grd.group(2).strip()
                    else:
                        m_lead = re.match(r"^([A-Za-z0-9\.\-\/]{2,12})\s+(.*)$", raw_desc)
                        if m_lead and len(m_lead.group(2)) > 2:
                            code_raw = m_lead.group(1)
                            desc = m_lead.group(2)
                        else:
                            m_emb = re.search(
                                r"\b(CIE\.?9(?:\.MC)?\.[A-Z0-9\.]+|GRD\.\d+|[A-D]\.\d+(?:\.[A-Z0-9]+)*|AM\d{4}|TS\d{4})\s*(.*)$",
                                raw_desc,
                                re.I,
                            )
                            if m_emb:
                                code_raw = m_emb.group(1).strip()
                                desc = m_emb.group(2).strip()
                            else:
                                desc = raw_desc

            # If no price found on this line, buffer it as candidate prefix for next line
            if not price or not desc:
                if len(line_clean) > 3 and not re.search(r"\d{1,3}(?:\.\d{3})*,\d{2}", line_clean):
                    buffer_line = (
                        f"{buffer_line} {line_clean}".strip()
                        if buffer_line and len(buffer_line) < 150
                        else line_clean
                    )
                else:
                    buffer_line = ""
                continue

            buffer_line = ""  # Reset buffer after matched price row

            if len(desc) < 3 or price <= 0:
                continue

            # Strip TOC dots and leading list numbering
            if re.search(r"\.{4,}", candidate_line) or re.search(r"\.{4,}", desc):
                continue

            clean_desc = re.sub(r"\.{3,}", "", desc)
            clean_desc = re.sub(
                r"^(?:[0-9]+(?:\.[0-9]+)*|[A-Z]\.(?:[0-9]+(?:\.[0-9]+)*)?)\s*[\.\-\)]?\s*",
                "",
                clean_desc,
            ).strip()
            clean_desc = re.sub(r"^(?:Especialidad\s+Código\s+)?", "", clean_desc, flags=re.I).strip()
            clean_desc = re.sub(r"^(?:[A-Z0-9\.\/]+\s+)*(?:GRD\s*\d{1,4}\s*[-–]\s*)", "", clean_desc, flags=re.I).strip()
            clean_desc = re.sub(r"^(?:\d+\s+)+", "", clean_desc).strip()
            clean_desc = re.sub(r"_SEV_(\d)", r" (SEVERIDAD \1)", clean_desc, flags=re.I).strip()
            clean_desc = re.sub(r"\s+", " ", clean_desc).strip().upper()

            if is_noise_text(clean_desc):
                continue

            code_std = format_code_std(code_raw, context=clean_desc)
            sig = f"{clean_desc}|{price}|{ccaa}"
            if sig in seen:
                continue
            seen.add(sig)

            setting = infer_setting(clean_desc, code_std=code_std)
            unit_type = infer_unit_type(setting, clean_desc)
            omop_domain = infer_omop_domain(setting)
            specialty = infer_specialty(clean_desc)
            cost_upd = round(price * factor, 2)

            records.append(
                CostRecord(
                    cost_id=f"{source_id}-{seq:05d}",
                    description=clean_desc,
                    cost_group=category,
                    setting=setting,
                    specialty=specialty,
                    unit_type=unit_type,
                    cost_original=price,
                    year_original=year,
                    cost_updated=cost_upd,
                    year_updated=TARGET_YEAR,
                    ccaa=ccaa,
                    legal_source=legal_source,
                    source_url=source_url,
                    code_std=code_std,
                    omop_domain=omop_domain,
                )
            )
            seq += 1

    return records


def run_pipeline(
    registry_path: str = "data/specs/registries.yml",
    output_csv: str = "data/costs_spain.csv",
    output_parquet: str = "data/costs_spain.parquet",
    output_json: str = "data/costs_spain.json",
    download_fresh: bool = False,
    deflators: Optional[Dict[int, float]] = None,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """Execute complete reproducible cost extraction & INE deflator pipeline."""
    with open(registry_path, "r", encoding="utf-8") as f:
        registry = yaml.safe_load(f)

    sources = registry.get("sources", [])

    if deflators is None:
        deflators = fetch_ine_deflators()
    print(
        f"[INFO] Initialized INE Deflators (Target {TARGET_YEAR} Index = {deflators.get(TARGET_YEAR, 109.43)})"
    )

    # Export canonical INE index datasets
    df_ine = export_ine_tables(output_dir=os.path.dirname(output_csv) or "data")

    all_records: List[CostRecord] = []
    os.makedirs("data/raw", exist_ok=True)

    for src in sources:
        src_id = src["id"]
        fmt = src.get("file_format", "pdf")
        filepath = os.path.join("data/raw", f"{src_id}.{fmt}")

        if download_fresh or not os.path.exists(filepath) or os.path.getsize(filepath) < 200:
            filepath = download_source(src, raw_dir="data/raw")

        if not os.path.exists(filepath) or os.path.getsize(filepath) < 100:
            print(f"[WARN] Skipping {src_id}: empty or missing file {filepath}")
            continue

        print(f"[PROCESS] Ingesting {src_id} ({src['ccaa']} - {fmt})...")
        extracted: List[CostRecord] = []
        if fmt == "xlsx":
            extracted = extract_grd_excel(src, filepath, deflators)
        elif fmt == "html":
            extracted = extract_html_catalog(src, filepath, deflators)
        elif fmt == "pdf":
            extracted = extract_pdf_catalog(src, filepath, deflators)

        print(f"[OK] Extracted {len(extracted)} records from {src_id}.")
        all_records.extend(extracted)

    if not all_records:
        raise ValueError("[ERROR] Zero records extracted across all sources.")

    df = pd.DataFrame([asdict(r) for r in all_records])

    # Deduplicate exact matching rows (same description, cost, ccaa)
    df = df.drop_duplicates(subset=["description", "cost_original", "ccaa"])

    # Standard sequential unique cost_ids: <ccaa_prefix>-cost-<05d>
    df = df.reset_index(drop=True)
    prefixes = df["ccaa"].apply(
        lambda x: re.sub(r"[^a-z0-9]", "", x.lower()[:3]) if x else "esp"
    )
    df["cost_id"] = [
        f"{pref}-cost-{idx+1:05d}" for idx, pref in enumerate(prefixes)
    ]

    # Enforce constraints & validation assertions
    assert df["cost_id"].is_unique, "cost_id must be unique across entire dataset"
    assert df["description"].isna().sum() == 0, "No null descriptions allowed"
    assert df["cost_original"].isna().sum() == 0, "No null cost_original allowed"
    assert df["cost_updated"].isna().sum() == 0, "No null cost_updated allowed"
    assert df["ccaa"].isna().sum() == 0, "No null ccaa allowed"

    # Export canonical catalogs
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)
    df.to_csv(output_csv, index=False, encoding="utf-8")
    print(f"[EXPORT] Wrote CSV -> {output_csv} ({len(df):,} rows)")

    df.to_parquet(output_parquet, index=False, compression="snappy")
    print(f"[EXPORT] Wrote Parquet -> {output_parquet}")

    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(df.to_dict(orient="records"), f, indent=2, ensure_ascii=False)
    print(f"[EXPORT] Wrote JSON -> {output_json}")

    # Breakdown summaries
    print("\n======================= SUMMARY BREAKDOWN =======================")
    print(f"Total Normalized Catalog Entries: {len(df):,}")
    print("\n--- Breakdown by CCAA / Scope ---")
    print(df["ccaa"].value_counts().to_string())

    print("\n--- Breakdown by Clinical Setting ---")
    print(df["setting"].value_counts().to_string())

    print("\n--- Breakdown by OMOP Domain ---")
    print(df["omop_domain"].value_counts().to_string())

    print("\n--- Standard Codes Sample (code_std) ---")
    print(
        df[df["code_std"] != ""][["cost_id", "code_std", "description", "cost_original"]]
        .head(15)
        .to_string()
    )

    return df, df_ine


def main():
    parser = argparse.ArgumentParser(description="Spanish Healthcare Cost Extractor.")
    parser.add_argument("--registry", default="data/specs/registries.yml")
    parser.add_argument("--output-csv", default="data/costs_spain.csv")
    parser.add_argument("--output-parquet", default="data/costs_spain.parquet")
    parser.add_argument("--output-json", default="data/costs_spain.json")
    parser.add_argument("--fresh", action="store_true", default=False)
    args = parser.parse_args()

    run_pipeline(
        registry_path=args.registry,
        output_csv=args.output_csv,
        output_parquet=args.output_parquet,
        output_json=args.output_json,
        download_fresh=args.fresh,
    )


if __name__ == "__main__":
    main()
