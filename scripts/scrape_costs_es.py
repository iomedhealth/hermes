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
import sys
import time
from dataclasses import asdict, dataclass
from typing import Any, Dict, List, Optional, Set, Tuple

import openpyxl
import pandas as pd
import pypdfium2
import yaml
from bs4 import BeautifulSoup

try:
    from scripts.download_costs_sources import (
        DEFAULT_SANIDAD_INDICES,
        TARGET_YEAR,
        IneIndexRecord,
        download_all_sources,
        download_source,
        export_ine_tables,
        fetch_ine_deflators,
    )
except ImportError:
    from download_costs_sources import (
        DEFAULT_SANIDAD_INDICES,
        TARGET_YEAR,
        IneIndexRecord,
        download_all_sources,
        download_source,
        export_ine_tables,
        fetch_ine_deflators,
    )

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
        r"\bCVE:[-\sA-Z0-9\/]+",
        r"\bNPE:[-\sA-Z0-9\/]+",
        r"\bDEPÓSITO\s+LEGAL\b",
        r"\bISSN:[-\s0-9X]+",
        r"\bES\s+COPIA\s+AUTÉNTICA\b",
        r"\bFIRMADO\s+POR\b",
        r"\bVERIFICACIÓN\s+[A-Za-z0-9]+",
        r"\bDIRECCIÓN\s+GENERAL\s+C\/\s+ÁLAVA\b",
        r"\bZUZENDARITZA\s+NAGUSIA\b",
        r"\bTFNO\.\s*\d+",
        r"\bEQUIPO\s+PROFESIONAL\s+ASIGNADO\b",
        r"\bEL\s+NÚMERO\s+DE\s+PLAZAS\s+MÍNIMO\b",
        r"\bPERSONAL:\s+EL\s+EQUIPO\b",
        r"\bRELACIÓN\s+NO\s+EXHAUSTIVA\b",
        r"\bEN\s+EL\s+SUPUESTO\s+DE\s+ESTANCIAS\b",
        r"\bADEMÁS\s+DEL\s+PRECIO\s+ESTABLECIDO\b",
        r"\bEXPRESIÓN:\s*PRECIO\b",
        r"\bPRECIOS?\s+SE\s+ESPECIFICAN\b",
        r"\bPRECIOS?\s+SERÁ\s+EL\s+ESTABLECIDO\b",
        r"\bPRECIOS?\s+SON\s+LOS\s+ESTABLECIDOS\b",
        r"\bSE\s+DETALLAN\s+EN\s+EL\s+ANEXO\b",
        r"\bRETRIBUCIÓN\s+DE\s+ACTIVIDADES\b",
        r"\bFORMACIÓN\s+(?:PROGRAMADA|NO\s+PROGRAMADA)\b",
        r"\bDISEÑO\s+ACTIVIDAD\s+TIPO\b",
        r"^\s*(?:TRAMO|NÚMERO|SUCESIVAS|EN\s+URGENCIAS|AMBULANTE\s+\d+|DE\s+ENFERMERÍA|COLGAJO|ALFA|SISTEMÁTICO|PORKM)\s*$",
        r"^[A-Z]\*{3,5}$",
    ]
    for pat in noise_patterns:
        if re.search(pat, t, re.I):
            return True

    # Check if string starts with dangling prepositions / conjunctions
    if re.match(r"^(?:Y|O|DE|EN|CON|SIN|DEL|POR|A|E|PARA)\s+[A-Z0-9_\-]{2,15}$", t):
        return True

    return False


def clean_description_text(desc: str) -> str:
    """Sanitize description by stripping headers, gazette footers, asterisks, and trailing punctuation."""
    if not desc:
        return ""
    t = desc.strip()

    # Gazette footers/headers
    t = re.sub(r"https?://\S+", "", t, flags=re.I)
    t = re.sub(r"www\.\S+", "", t, flags=re.I)
    t = re.sub(r"\b(?:BOC|BOCYL|BOJA|BOPV|BORM|DOGV|DOGC|DOE|BOE|BOPA|BOR|BON)[-\sA-Z0-9\/]+", "", t, flags=re.I)
    t = re.sub(r"\bCVE:[-\sA-Z0-9\/]+", "", t, flags=re.I)
    t = re.sub(r"\bNPE:[-\sA-Z0-9\/]+", "", t, flags=re.I)
    t = re.sub(r"\bDEP[ÓO]SITO\s+LEGAL:[-\sA-Z0-9\/]+", "", t, flags=re.I)
    t = re.sub(r"\bISSN:[-\s0-9X]+", "", t, flags=re.I)
    t = re.sub(r"\bES\s+COPIA\s+AUT[ÉE]NTICA\b.*", "", t, flags=re.I)
    t = re.sub(r"\bFIRMADO\s+POR\b.*", "", t, flags=re.I)
    t = re.sub(r"\bVERIFICACI[ÓO]N\b.*", "", t, flags=re.I)
    t = re.sub(r"\bN[ÚU]M\.\s+\d+\s+DE\s+[\d\-IVXLCDM]+\s+\d+\/?", "", t, flags=re.I)
    t = re.sub(r"\bC[ÓO]D\.\s+\d{4}-?", "", t, flags=re.I)

    # Leading section / table artifacts
    t = re.sub(r"^(?:DESCRIPCI[ÓO]N\s+(?:PROCEDIMIENTOS\s+)?PRECIO\s+M[ÁA]X\.?\s*)", "", t, flags=re.I)
    t = re.sub(r"^(?:(?:C[ÓO]DIGO\s+)?(?:CONCEPTO|DENOMINACI[ÓO]N|PRESTACI[ÓO]N|PROCEDIMIENTO)\s+(?:PRECIO|IMPORTE|EUROS?|\/|\(€\)|€)*\s*)", "", t, flags=re.I)
    t = re.sub(r"^(?:[A-ZÁÉÍÓÚÑ\s]+\s+)?CÓDIGO\s+CONCEPTO\s+PRECIO\s*\(€\)\s*(?:[A-Z]\.\d+(?:\.[0-9]+)*\s*)?", "", t, flags=re.I)
    t = re.sub(r"^(?:ASISTENCIA\s+AMBULATORIA\s+IMPORTES\s*)", "", t, flags=re.I)
    t = re.sub(r"^(?:FACTURABLES\s+TARIFA\s*)", "", t, flags=re.I)
    t = re.sub(r"^(?:DENOMINACI[ÓO]N\s+IMPORTE\s*)", "", t, flags=re.I)
    t = re.sub(r"^(?:PRECIO\s*\(€\)\s*)", "", t, flags=re.I)
    t = re.sub(r"^(?:HOSPITALES\s+)", "", t, flags=re.I)
    t = re.sub(r"^(?:B\d(?:\s+\d+)+\s*)", "", t, flags=re.I)
    t = re.sub(r"^(?:E\s*03(?:\.[0-9]+)+\s*)", "", t, flags=re.I)
    t = re.sub(r"^(?:317\.\d(?:\.[0-9]+)+\s*)", "", t, flags=re.I)
    t = re.sub(r"^(?:(?:CIE\.?9(?:\.MC)?\.[0-9A-Z\.]+|\d{2}\.\d{1,2}[A-Za-z]?|[0-9A-Z]{7})\s+)", "", t, flags=re.I)
    t = re.sub(r"^(?:GRD\s*\d{1,4}(?:\.\d{1,2})?\s*[-–]?\s*)", "", t, flags=re.I)

    # Footnotes & artifacts
    t = re.sub(r"_SEV_(\d)", r" (SEVERIDAD \1)", t, flags=re.I)
    t = re.sub(r"_Sev_(\d)", r" (SEVERIDAD \1)", t)
    t = re.sub(r"\(\s*[*]+\s*\)", "", t)
    t = re.sub(r"(?<![A-Z0-9])\*(?![0-9])", "", t)
    t = re.sub(r"\s*\(\s*\d+\s*\)$", "", t)
    t = re.sub(r"\s*\[\s*\d+\s*\]$", "", t)
    t = re.sub(r"\s*\(\s*#\s*\)$", "", t)
    t = re.sub(r"\s*\*{1,4}$", "", t)

    # Multi-spaced numeric indexing headers (e.g. "2 2 ", "4 1 4 ", "1 304 ")
    t = re.sub(r"^(?:[A-Z]\d\s+)?(?:\d+\s+){2,}", "", t).strip()

    # Regional item code tags with underscore (e.g. "ANVCE-SCAT_", "EC----DIGE_", "CASP2_", "TCTOR-AREM_")
    t = re.sub(r"^[A-Z0-9\-]{2,10}(?:-[A-Z0-9\-]+)?_\s*", "", t).strip()

    # Leading list numbering (e.g. "1.1", "A.1.")
    t = re.sub(r"^(?:[0-9]+(?:\.[0-9]+)*|[A-Z]\.(?:[0-9]+(?:\.[0-9]+)*)?)\s*[\.\-\)]?\s*", "", t).strip()

    # Leading orphan punctuation / brackets / parentheses
    t = re.sub(r"^[)\],:\-_/\\.]+\s*", "", t).strip()

    # Casing and whitespace
    t = re.sub(r"\s+", " ", t).strip().upper()

    # Broken spaced words (e.g. SANGR E -> SANGRE, OR INA -> ORINA)
    t = re.sub(r"\bSANGR\s+E\b", "SANGRE", t)
    t = re.sub(r"\bOR\s+INA\b", "ORINA", t)

    # Trailing punctuation
    t = re.sub(r"[.,\-_:;/\\+]+$", "", t).strip()
    return t


def infer_setting(desc: str, code_std: str = "") -> str:
    """Infer clinical setting with APR-GRD precedence and regex-hardened keywords."""
    d = desc.lower()

    # Precedence 1: APR-GRD casemix categories default to Inpatient unless explicit CMA
    if code_std.startswith("APR-GRD:"):
        if any(k in d for k in ["cma", "ambulatori", "sin ingreso", "mayor ambulatoria"]):
            return "Procedures"
        return "Inpatient"

    # Precedence 2: Consultations & Outpatient visits (including specialized consultations)
    if re.search(r"\b(?:consulta|consultas|visita|visitas|interconsulta|interconsultas|revisi[oó]n|revisiones)\b", d):
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
                "médica ap",
            ]
        ):
            return "Primary Care"
        return "Outpatient"

    # Precedence 3: ICU / Critical Care (hardened against substring matches like 'resolución', 'sustitución')
    if (
        re.search(r"\b(?:uci|uvi|cuidados intensivos|vigilancia intensiva|cr[ií]ticos|críticos|quemados)\b", d)
        or (re.search(r"\breanimaci[oó]n\b", d) and "consulta" not in d)
    ) and not re.search(r"\b(?:m[oó]vil|ambulancia|transporte)\b", d):
        return "ICU"

    # Precedence 4: Emergency Care & Urgent Medical Transport
    if re.search(
        r"\b(?:urgencia|urgencias|emergencia|emergencias|112|061|atenci[oó]n continuada|atencion continuada|guardia m[eé]dica|soporte vital|ambulancia medicalizada|interurbano|traslado urgente)\b",
        d,
    ):
        return "Emergency"

    # Precedence 5: Primary Care / Oral Health Programs
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
            "salud bucodental",
            "médica ap",
            "asistencia bucodental infantil",
            "dental",
        ]
    ):
        return "Primary Care"

    # Precedence 6: Inpatient Hospitalization
    if re.search(
        r"\b(?:hospitaliz|estancia|ingreso|cama ocupada|internamiento|convalecencia|craneotom|trasplante|traqueostom|infarto|neumon[ií]a|sepsis)\b",
        d,
    ):
        return "Inpatient"

    # Precedence 7: Diagnostics, Imaging, and Clinical Laboratory
    if (
        re.search(
            r"\b(?:resonancia|tac|tc|tomograf[ií]a|radiolog[ií]a|radiograf[ií]a|ecograf[ií]a|ecocardiograf[ií]a|gammagraf[ií]a|spect|pet-tac|pet|endoscop|mamograf[ií]a|electrocardiograma|ecg|eeg|electromiograf|espirometr|audiometr|campimetr|densitometr|ergometr|holter|polisomnograf|alergia|provocaci|analitica|analítica|laboratorio|biopsia|determinaci|estudio genetico|serolog|cultivo|citolog|perfil|tinci|microbiolog|ige|igg|igm|suero|plasma|orina|lcr|l[ií]quido|bioqu[ií]mica|hematimetr|hemograma|frotis|ant[ií]geno|anticuerpo|inmunoglobulina|pcr|genotipado|cariotipo|secuenciaci|[aá]cido|amilasa|alb[uú]mina|fosfatasa|glucosa|creatinina|colesterol|triglic[eé]ridos|transaminasas|bilirrubina|urea|troponina|tiroxina|tsh|ferritina|hierro|potasio|sodio|calcio|gasometr|coagulaci|hemostasia|d-d[ií]mero|hla-|cyp)\b",
            d,
        )
        or code_std.startswith(("REGIONAL:LQ", "REGIONAL:E03.1.6"))
    ):
        return "Diagnostics"

    # Precedence 8: Procedures, CMA, Interventions, Surgeries
    if (
        re.search(
            r"\b(?:quirurg|quirúrg|cirug[ií]a|intervenci[oó]n|artroscop|escisi[oó]n|reparaci[oó]n|injerto|sustituci[oó]n|osteotom|amigdalectom|catarata|safenectom|f[ií]stul|gastrectom|implante|pr[oó]tesis|endarterectom|facoemulsif|tiroidectom|mastectom|colecistectom|hernioplastia|apendicectom|amputaci[oó]n|hemodi[aá]lisis|litotricia|cateterismo|angioplastia|embolizaci[oó]n|drenaje|cma|legrado|ces[aá]rea|parto|ablaci[oó]n|infiltraci[oó]n|paracentesis|toracocentesis|artrocentesis|bloqueo|traqueostom|marcapasos|endopr[oó]tesis|stent|desfibrilador|valvuloplastia|extirpaci[oó]n|resecci[oó]n|liberaci[oó]n)\b",
            d,
        )
        or code_std.startswith(("ICD-9-CM:", "ICD-10-PCS:", "REGIONAL:CMA"))
    ):
        return "Procedures"

    # Precedence 9: Outpatient Care / Consultations / Day Hospital
    return "Outpatient"


def infer_unit_type(setting: str, desc: str) -> str:
    d = desc.lower()
    if any(k in d for k in ["por km", "cada km", "por cada km", "porkm", "/km"]):
        return "per_km"
    if any(
        k in d
        for k in [
            "sesion",
            "sesión",
            "tratamiento continuo",
            "hemodialisis",
            "hemodiálisis",
            "fisioterapia",
            "rehabilitaci",
        ]
    ):
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
        ("maxilofacial", "Cirugía Maxilofacial"),
        ("estomatol", "Odontología y Estomatología"),
        ("dental", "Odontología y Estomatología"),
        ("bucodental", "Odontología y Estomatología"),
        ("plástica", "Cirugía Plástica"),
        ("plastica", "Cirugía Plástica"),
        ("cardiovascular", "Cirugía Cardiovascular"),
        ("vascular", "Cirugía Vascular"),
        ("torácic", "Cirugía Torácica"),
        ("toracic", "Cirugía Torácica"),
        ("neurocirug", "Neurocirugía"),
        ("pediatr", "Pediatría"),
        ("neonat", "Pediatría"),
        ("trauma", "Traumatología"),
        ("ortopéd", "Traumatología"),
        ("ortoped", "Traumatología"),
        ("artroscop", "Traumatología"),
        ("cadera", "Traumatología"),
        ("rodilla", "Traumatología"),
        ("fractura", "Traumatología"),
        ("oftalm", "Oftalmología"),
        ("catarata", "Oftalmología"),
        ("ocular", "Oftalmología"),
        ("ojo", "Oftalmología"),
        ("córnea", "Oftalmología"),
        ("cornea", "Oftalmología"),
        ("retina", "Oftalmología"),
        ("dermat", "Dermatología"),
        ("cutáne", "Dermatología"),
        ("piel", "Dermatología"),
        ("cardio", "Cardiología"),
        ("coronar", "Cardiología"),
        ("miocard", "Cardiología"),
        ("arritmi", "Cardiología"),
        ("neuro", "Neurología"),
        ("cerebr", "Neurología"),
        ("crane", "Neurología"),
        ("digest", "Aparato Digestivo"),
        ("gastroc", "Aparato Digestivo"),
        ("endoscop", "Aparato Digestivo"),
        ("colon", "Aparato Digestivo"),
        ("gástric", "Aparato Digestivo"),
        ("ginec", "Ginecología"),
        ("obstetr", "Ginecología"),
        ("parto", "Ginecología"),
        ("cesárea", "Ginecología"),
        ("uterin", "Ginecología"),
        ("mama", "Ginecología"),
        ("urolog", "Urología"),
        ("renal", "Nefrología"),
        ("nefrolog", "Nefrología"),
        ("dialisis", "Nefrología"),
        ("diálisis", "Nefrología"),
        ("riñón", "Nefrología"),
        ("rinon", "Nefrología"),
        ("otorrino", "Otorrinolaringología"),
        ("amigdal", "Otorrinolaringología"),
        ("oído", "Otorrinolaringología"),
        ("laring", "Otorrinolaringología"),
        ("nasal", "Otorrinolaringología"),
        ("sinus", "Otorrinolaringología"),
        ("nuclear", "Medicina Nuclear"),
        ("gammagraf", "Medicina Nuclear"),
        ("spect", "Medicina Nuclear"),
        ("pet", "Medicina Nuclear"),
        ("radiolog", "Radiología"),
        ("radiodiagn", "Radiología"),
        ("resonancia", "Radiología"),
        ("tomograf", "Radiología"),
        ("ecograf", "Radiología"),
        ("radiograf", "Radiología"),
        ("rehab", "Rehabilitación"),
        ("fisioter", "Rehabilitación"),
        ("logoped", "Rehabilitación"),
        ("psiquiat", "Psiquiatría"),
        ("psicol", "Psiquiatría"),
        ("salud mental", "Psiquiatría"),
        ("anest", "Anestesiología"),
        ("reanim", "Anestesiología"),
        ("dolor", "Anestesiología"),
        ("radioter", "Oncología Radioterápica"),
        ("oncolog", "Oncología"),
        ("neoplasi", "Oncología"),
        ("tumor", "Oncología"),
        ("hematol", "Hematología"),
        ("sangre", "Hematología"),
        ("transfus", "Hematología"),
        ("plaqueta", "Hematología"),
        ("respirat", "Neumología"),
        ("pulmon", "Neumología"),
        ("asma", "Neumología"),
        ("bronco", "Neumología"),
        ("tórax", "Neumología"),
        ("torax", "Neumología"),
        ("hepatic", "Hepatología"),
        ("hígado", "Hepatología"),
        ("higado", "Hepatología"),
        ("alerg", "Alergología"),
        ("inmuno", "Inmunología"),
        ("patológ", "Anatomía Patológica"),
        ("patolog", "Anatomía Patológica"),
        ("biopsia", "Anatomía Patológica"),
        ("autopsia", "Anatomía Patológica"),
        ("citolog", "Anatomía Patológica"),
        ("genétic", "Genética"),
        ("genetic", "Genética"),
        ("bioquím", "Bioquímica Clínica"),
        ("bioquim", "Bioquímica Clínica"),
        ("microbiol", "Microbiología"),
        ("infecc", "Enfermedades Infecciosas"),
        ("endocrin", "Endocrinología"),
        ("reumat", "Reumatología"),
        ("geriatr", "Geriatría"),
        ("atención primaria", "Atención Primaria"),
        ("centro salud", "Atención Primaria"),
        ("médico de familia", "Atención Primaria"),
        ("médica ap", "Atención Primaria"),
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

    # APR-GRD formats
    m_grd = re.match(r"^(?:APR[-_ ]?GRD|GRD)\s*[:\-]?\s*(\d{1,4})(?:[-–\.](\d{1,2}))?$", c, re.I)
    if m_grd:
        grd_num = m_grd.group(1).zfill(3)
        sev = m_grd.group(2)
        if sev:
            sev_clean = str(int(sev)) if sev.isdigit() else sev
            return f"APR-GRD:{grd_num}-{sev_clean}"
        return f"APR-GRD:{grd_num}"

    m_g = re.match(r"^(\d{1,4})\s*G\s*(\d+)$", c, re.I)
    if m_g:
        return f"APR-GRD:{m_g.group(1).zfill(3)}-{m_g.group(2)}"

    # ICD-9-CM
    m_cie = re.match(r"^CIE\.?9(?:\.MC)?\.([0-9A-Z\.]+)$", c, re.I)
    if m_cie:
        return f"ICD-9-CM:{m_cie.group(1)}"
    if re.match(r"^\d{2}\.(?:\d{1,2}[A-Za-z]?|[Xx]{1,2})$", c):
        return f"ICD-9-CM:{c.upper()}"

    # SAP code (7-8 digits starting with 7 or 10 or in sap context)
    if re.match(r"^\d{7,8}$", c) and (c.startswith(("7", "10")) or "sap" in context.lower()):
        return f"SAP:{c}"

    # ICD-10-PCS (7 chars)
    if (
        re.match(r"^[0-9A-HJ-NP-Z]{7}$", c, re.I)
        and c.upper() not in SPANISH_WORDS_7
        and not re.match(r"^(?:PD|TR|RA|MN|LQ|V0|AM|TS)\d{5}$", c, re.I)
        and c[0].upper() in "0123456789BCDFGHX"
    ):
        c_up = c.upper()
        if not (c_up.isalpha() and not (c_up.endswith("ZZ") or c_up.endswith("ZX") or c_up.endswith("KZ"))):
            return f"ICD-10-PCS:{c_up}"

    # National Drug Code (6 digits)
    if re.match(r"^\d{6}$", c) and any(
        k in context.lower() for k in ["farmac", "medicamento", "cn", "nomenclator"]
    ):
        return f"CN:{c}"

    # Regional codes
    if (
        re.match(r"^(?:AM|TS)\d{4}$", c, re.I)
        or re.match(r"^CMA\d{3}$", c, re.I)
        or re.match(r"^V03[A-Z0-9]+$", c, re.I)
        or re.match(r"^LQ\d{5}[A-Z]?$", c, re.I)
        or re.match(r"^(?:PD|TR|RA|MN)\d{5}$", c, re.I)
        or re.match(r"^E\s*03\.[0-9\.]+$", c)
        or re.match(r"^E03\.[0-9\.]+$", c)
        or re.match(r"^[A-D]\.\d+(?:\.[A-Z0-9]+)*$", c)
        or re.match(r"^\d{2}\.\d+[A-Za-z]+$", c)
        or re.match(r"^70\d{4}$", c)
        or re.match(r"^C\.A\.[A-Z0-9\.]+$", c)
        or re.match(r"^C\.\d+$", c)
        or re.match(r"^317\.\d(?:\.[0-9]+)+$", c)
        or re.match(r"^\d+\.\d+(?:\.\d+)+$", c)
    ):
        clean_reg = c.replace(" ", "")
        return f"REGIONAL:{clean_reg}"

    return ""


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

        clean_desc = clean_description_text(desc)
        if not clean_desc or is_noise_text(clean_desc):
            continue

        setting = "Procedures" if "quirúrg" in tipo.lower() else "Inpatient"
        omop_domain = "Procedure" if setting == "Procedures" else "Visit"
        unit_type = "per_procedure" if setting == "Procedures" else "per_episode"
        specialty = infer_specialty(clean_desc)
        cost_orig = round(float(coste), 2)
        cost_upd = round(cost_orig * factor, 2)

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
            cells = [c.get_text(" ", strip=True) for c in row.find_all(["td", "th"])]
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

            # Layout 2: Madrid 5/6-column [Epígrafe, GRD APR, Gravedad, ..., Descripción, Importe]
            elif (
                len(cells) >= 5
                and any("E 03" in c or "E03" in c for c in cells[:2])
                and parse_price(cells[-1])
            ):
                price = parse_price(cells[-1])
                epigrafe = cells[0].replace(" ", "")
                if len(cells) >= 6 and cells[1].isdigit() and cells[2].isdigit():
                    code_raw = f"APR-GRD:{cells[1].zfill(3)}-{cells[2]}"
                    desc = cells[4]
                elif len(cells) >= 5 and cells[1].isdigit() and cells[2].isdigit():
                    code_raw = f"APR-GRD:{cells[1].zfill(3)}-{cells[2]}"
                    desc = cells[3]
                else:
                    code_raw = f"REGIONAL:{epigrafe}"
                    # Find first text column after epigrafe
                    for col_idx in range(1, len(cells) - 1):
                        if len(cells[col_idx]) > 3 and not parse_price(cells[col_idx]):
                            desc = cells[col_idx]
                            break
                    if not desc:
                        desc = cells[-2]

            # Layout 3: Cataluña GRD table [Regional Code, Description with GRD xxx.xx, Price]
            elif (
                len(cells) >= 3
                and re.match(r"^V03[HM]\d+", cells[0], re.I)
                and parse_price(cells[-1])
            ):
                price = parse_price(cells[-1])
                raw_d = cells[1]
                m_grd = re.search(r"GRD\s*(\d{1,4})\.0?(\d)", raw_d, re.I)
                if m_grd:
                    code_raw = f"APR-GRD:{m_grd.group(1).zfill(3)}-{m_grd.group(2)}"
                    desc = re.sub(r"^GRD\s*\d{1,4}\.0?\d\s*", "", raw_d, flags=re.I).strip()
                else:
                    code_raw = cells[0]
                    desc = raw_d

            # Layout 4: Baleares 3-column [Description, Price, SAP]
            elif (
                len(cells) == 3
                and parse_price(cells[1])
                and re.match(r"^\d{7}$", cells[2].strip())
            ):
                desc = cells[0]
                price = parse_price(cells[1])
                code_raw = f"SAP:{cells[2].strip()}"

            # Layout 5: Navarra 4-column tables
            elif len(cells) == 4 and parse_price(cells[3]):
                price = parse_price(cells[3])
                if re.match(r"^\d+\s*G\s*\d+$", cells[0].strip(), re.I):
                    code_raw = cells[0].replace(" ", "")
                    desc = cells[1]
                elif re.match(r"^[0-9A-Z\*]{3,7}$", cells[1].strip()):
                    code_raw = cells[1].strip()
                    desc = cells[2]
                else:
                    code_raw = cells[0]
                    desc = cells[1] if len(cells[1]) > len(cells[2]) else cells[2]

            # Layout 6: Standard [Code, Desc, Price] or [Code, Desc, Weight, Price]
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

            clean_desc = clean_description_text(desc)
            if not clean_desc or len(clean_desc) < 3 or is_noise_text(clean_desc):
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

        clean_desc = clean_description_text(raw_desc)
        if not clean_desc or price <= 0 or code in seen or is_noise_text(clean_desc):
            continue
        seen.add(code)

        code_std = format_code_std(code, context=clean_desc)
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

            # If line ends in _Sev_1 or similar severity marker, continue buffering
            if re.search(r"_(?:Sev|SEV)_\d\s*$", candidate_line):
                buffer_line = candidate_line
                continue

            if not any(ch.isdigit() for ch in candidate_line):
                buffer_line = line_clean if len(line_clean) < 150 else ""
                continue

            desc, code_raw, price = None, None, None

            # Pattern 1: País Vasco GRD
            m_pvas_grd = re.search(
                r"^(\d+\s*G\s*\d+)\s+(.+?)\s+Gravedad\s+\d+\s+[\d\,]+\s+(\d{1,3}(?:\.\d{3})*|\d+)\s+(\d+)",
                candidate_line,
            )
            if m_pvas_grd:
                code_raw = m_pvas_grd.group(1).replace(" ", "")
                desc = m_pvas_grd.group(2).strip()
                price = parse_price(m_pvas_grd.group(3))
            else:
                # Pattern 1b: La Rioja / Regional GRD layout (e.g. "E.1.5 21 G 1 Craneotomía excepto por trauma 10.410 3.751" or "20 G 1 Craneotomía...")
                m_rio_grd = re.search(
                    r"^(?:E\.\d+(?:\.\d+)*\s+)?(\d{1,4})\s+G\s*([1-4])\s+(.+?)\s+(\d{1,3}(?:\.\d{3})*|\d+)(?:\s+(\d{1,3}(?:\.\d{3})*|\d+))?$",
                    candidate_line,
                )
                if m_rio_grd:
                    grd_num = m_rio_grd.group(1).zfill(3)
                    sev_num = m_rio_grd.group(2)
                    code_raw = f"APR-GRD:{grd_num}-{sev_num}"
                    desc = m_rio_grd.group(3).strip()
                    price = parse_price(m_rio_grd.group(4))
                else:
                    # Pattern 2: País Vasco procedures / lab / tests with SAP article ID (100xxxxx)
                    m_pvas_proc = re.search(
                        r"^([A-ZÁÉÍÓÚÑa-záéíóúñ\s\.\/\-\,\(\)]+?)\s+(?:\d+(?:[,\.]\d+)?\s+)?(\d{1,3}(?:\.\d{3})*|\d+)\s+(?:(?:\d{1,3}(?:\.\d{3})*|\d+)\s+)?(100\d{5})\b",
                        candidate_line,
                    )
                    if m_pvas_proc and not is_noise_text(m_pvas_proc.group(1)):
                        desc = m_pvas_proc.group(1).strip()
                        price = parse_price(m_pvas_proc.group(2))
                        code_raw = f"SAP:{m_pvas_proc.group(3)}"
                    else:
                        # Pattern 3: General decimal or integer price at line end
                        m_gen_end = re.search(
                            r"(\d{1,3}(?:\.\d{3})*,\d{2}|\d+,\d{2}|\d{1,3}(?:\.\d{3})+|\d+\.\d{2}|(?<!_)\b\d{1,6}\b)\s*€?$",
                            candidate_line,
                        )
                        if m_gen_end:
                            matched_str = m_gen_end.group(1)
                            # Guard: reject bare isolated integer line endings from pure section index numbers (e.g. 'B2 2 4 1 27')
                            if ("," not in matched_str and "." not in matched_str) and len(re.sub(r"[\d\s\.\-_/]", "", candidate_line)) < 4:
                                price = None
                            else:
                                price = parse_price(matched_str)
                                raw_desc = candidate_line[: m_gen_end.start()].strip()

                                # Check if raw_desc contains embedded GRD (e.g. Andalusia B2 1 1 129 GRD 055 - ...)
                                m_grd = re.search(
                                    r"GRD\s*0?(\d{1,4})\s*[-–]\s*(.*?)(?:_?SEV[_\s]?(\d))?$",
                                    raw_desc,
                                    re.I,
                                )
                                if m_grd:
                                    grd_num = m_grd.group(1).zfill(3)
                                    sev_num = m_grd.group(3)
                                    code_raw = f"APR-GRD:{grd_num}-{sev_num}" if sev_num else f"APR-GRD:{grd_num}"
                                    desc = m_grd.group(2).strip()
                                else:
                                    # Check leading code or embedded regional codes
                                    m_lead = re.match(r"^([A-Za-z0-9\.\-\/]{2,12})\s+(.*)$", raw_desc)
                                    if m_lead and len(m_lead.group(2)) > 2 and not m_lead.group(1).upper().startswith(("ART", "NUM", "PAG")):
                                        code_raw = m_lead.group(1)
                                        desc = m_lead.group(2)
                                    else:
                                        m_emb = re.search(
                                            r"\b(CIE\.?9(?:\.MC)?\.[A-Z0-9\.]+|GRD\.\d+|[A-D]\.\d+(?:\.[A-Z0-9]+)*|AM\d{4}|TS\d{4}|317\.\d+(?:\.[0-9]+)*|70\d{4}|0[12]\.\d+[A-Z]+)\s*(.*)$",
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

            clean_desc = clean_description_text(desc)
            if not clean_desc or len(clean_desc) < 3 or is_noise_text(clean_desc):
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


def extract_source_records(
    src: Dict[str, Any],
    filepath: str,
    deflators: Optional[Dict[int, float]] = None,
) -> List[CostRecord]:
    """Extract and standardize records from a single local file (PDF, XLSX, HTML)."""
    if src.get("id") == "sns-2024-siap":
        # SIAP glossary PDF contains statistical definitions, not direct tariff rates
        return []
    if deflators is None:
        deflators = fetch_ine_deflators()
    fmt = src.get("file_format", "pdf")
    if fmt == "xlsx":
        return extract_grd_excel(src, filepath, deflators)
    elif fmt == "html":
        return extract_html_catalog(src, filepath, deflators)
    elif fmt == "pdf":
        return extract_pdf_catalog(src, filepath, deflators)
    return []


def consolidate_and_export(
    records: List[CostRecord],
    output_csv: str = "data/costs_spain.csv",
    output_parquet: str = "data/costs_spain.parquet",
    output_json: str = "data/costs_spain.json",
) -> pd.DataFrame:
    """Deduplicate, assign sequential cost_ids, validate invariants, and write catalog artifacts."""
    if not records:
        raise ValueError("[ERROR] Zero records provided for catalog compilation.")

    df = pd.DataFrame([asdict(r) for r in records])

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
    os.makedirs(os.path.dirname(output_csv) or ".", exist_ok=True)
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

    return df


def run_pipeline(
    registry_path: str = "data/specs/registries.yml",
    raw_dir: str = "data/raw",
    output_csv: str = "data/costs_spain.csv",
    output_parquet: str = "data/costs_spain.parquet",
    output_json: str = "data/costs_spain.json",
    download_fresh: bool = False,
    source_id: Optional[str] = None,
    ccaa: Optional[str] = None,
    deflators: Optional[Dict[int, float]] = None,
    limit_preview: Optional[int] = None,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """Execute complete 100% offline cost extraction, normalization, and catalog compilation."""
    with open(registry_path, "r", encoding="utf-8") as f:
        registry = yaml.safe_load(f)

    sources = registry.get("sources", [])
    if source_id:
        sources = [s for s in sources if s["id"] == source_id]
        if not sources:
            raise ValueError(f"[ERROR] Source ID '{source_id}' not found in registry.")
    elif ccaa:
        sources = [s for s in sources if s.get("ccaa", "").lower() == ccaa.lower()]
        if not sources:
            raise ValueError(f"[ERROR] No sources found matching CCAA '{ccaa}'.")

    if deflators is None:
        deflators = fetch_ine_deflators()
    print(
        f"[INFO] Initialized INE Deflators (Target {TARGET_YEAR} Index = {deflators.get(TARGET_YEAR, 109.43)})"
    )

    # Export canonical INE index datasets
    df_ine = export_ine_tables(output_dir=os.path.dirname(output_csv) or "data")

    all_records: List[CostRecord] = []

    for src in sources:
        src_id = src["id"]
        fmt = src.get("file_format", "pdf")
        filepath = os.path.join(raw_dir, f"{src_id}.{fmt}")

        if download_fresh or not os.path.exists(filepath) or os.path.getsize(filepath) < 100:
            if download_fresh:
                filepath = download_source(src, raw_dir=raw_dir, force=True)
            elif not os.path.exists(filepath):
                print(
                    f"[WARN] Missing {filepath}. Run 'python scripts/download_costs_sources.py --source-id {src_id}' to download it."
                )
                continue

        if not os.path.exists(filepath) or os.path.getsize(filepath) < 100:
            print(f"[WARN] Skipping {src_id}: empty or missing file {filepath}")
            continue

        print(f"[PROCESS] Ingesting {src_id} ({src['ccaa']} - {fmt})...")
        extracted = extract_source_records(src, filepath, deflators)
        print(f"[OK] Extracted {len(extracted)} records from {src_id}.")
        all_records.extend(extracted)

    if not all_records:
        raise ValueError("[ERROR] Zero records extracted across selected sources.")

    if limit_preview is not None and limit_preview > 0:
        df_preview = pd.DataFrame([asdict(r) for r in all_records[:limit_preview]])
        print(f"\n[PREVIEW] Showing first {len(df_preview)} records (offline preview mode, no file overwrite):")
        print(df_preview[["cost_id", "ccaa", "setting", "omop_domain", "code_std", "description", "cost_original", "cost_updated"]].to_string())
        return df_preview, df_ine

    df = consolidate_and_export(
        records=all_records,
        output_csv=output_csv,
        output_parquet=output_parquet,
        output_json=output_json,
    )

    return df, df_ine


def main():
    parser = argparse.ArgumentParser(description="Spanish Healthcare Cost Offline Scraper & Catalog Extractor.")
    parser.add_argument("--registry", default="data/specs/registries.yml", help="Path to registries.yml")
    parser.add_argument("--raw-dir", default="data/raw", help="Directory containing cached raw files")
    parser.add_argument("--source-id", default=None, help="Extract only a specific source ID")
    parser.add_argument("--ccaa", default=None, help="Extract only sources for a specific CCAA")
    parser.add_argument("--output-csv", default="data/costs_spain.csv", help="Destination CSV catalog")
    parser.add_argument("--output-parquet", default="data/costs_spain.parquet", help="Destination Parquet catalog")
    parser.add_argument("--output-json", default="data/costs_spain.json", help="Destination JSON catalog")
    parser.add_argument("--limit-preview", type=int, default=None, help="Preview N records without writing files")
    parser.add_argument("--fresh", action="store_true", default=False, help="Force fresh download if missing")
    args = parser.parse_args()

    run_pipeline(
        registry_path=args.registry,
        raw_dir=args.raw_dir,
        output_csv=args.output_csv,
        output_parquet=args.output_parquet,
        output_json=args.output_json,
        download_fresh=args.fresh,
        source_id=args.source_id,
        ccaa=args.ccaa,
        limit_preview=args.limit_preview,
    )


if __name__ == "__main__":
    main()
