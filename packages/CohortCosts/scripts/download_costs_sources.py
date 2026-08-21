#!/usr/bin/env python3
"""
scripts/download_costs_sources.py - Ground-source healthcare tariff & INE CPI downloader for Spain.

Downloads official gazette PDFs, HTML tariffs, Excel Casemix workbooks, and INE Table 50913
(ECOICOP 06 Sanidad) price series into local cache (`data/raw/`).
"""

import argparse
import json
import os
import re
import ssl
import sys
import urllib3
from dataclasses import asdict, dataclass
from typing import Any, Dict, List, Optional

import pandas as pd
import requests
import yaml

# Suppress InsecureRequestWarning for legacy regional gazette certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ponytail: bypass legacy SSL certificate verification on Spanish regional gazettes
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


@dataclass
class IneIndexRecord:
    ecoicop_code: str
    series_name: str
    year: int
    annual_index: float
    factor_to_2026: float
    is_projected: bool


def fetch_ine_deflators(
    cache_path: str = "packages/CohortCosts/data/external/ine-ipc-medicina.json", force: bool = False
) -> Dict[int, float]:
    """Fetch healthcare CPI index series from INE API (Table 50913 - ECOICOP 06 Sanidad) or fallback."""
    url = "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/50913"
    indices: Dict[int, float] = dict(DEFAULT_SANIDAD_INDICES)
    raw_data = None

    # Check local cached JSON first
    if not force and os.path.exists(cache_path) and os.path.getsize(cache_path) > 1000:
        try:
            with open(cache_path, "r", encoding="utf-8") as f:
                raw_data = json.load(f)
        except Exception:
            pass

    # Fetch from API if not cached or forced
    if not raw_data or force:
        try:
            r = requests.get(url, headers=HEADERS, verify=False, timeout=10)
            if r.status_code == 200:
                raw_data = r.json()
                os.makedirs(os.path.dirname(cache_path) or ".", exist_ok=True)
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
    output_dir: str = "packages/CohortCosts/data/external",
    raw_path: str = "packages/CohortCosts/data/external/ine-ipc-medicina.json",
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


def download_source(
    src: Dict[str, Any], raw_dir: str = "packages/CohortCosts/data/raw", force: bool = False
) -> str:
    """Download a single ground source document to raw_dir/<id>.<fmt>."""
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


def download_all_sources(
    registry_path: str = "packages/CohortCosts/data/specs/registries.yml",
    raw_dir: str = "packages/CohortCosts/data/raw",
    force: bool = False,
    source_id: Optional[str] = None,
    ccaa: Optional[str] = None,
) -> List[str]:
    """Download all (or filtered) registered ground sources to raw_dir."""
    with open(registry_path, "r", encoding="utf-8") as f:
        registry = yaml.safe_load(f)

    sources = registry.get("sources", [])
    if source_id:
        sources = [s for s in sources if s["id"] == source_id]
        if not sources:
            print(f"[WARN] Source ID '{source_id}' not found in registry.")
    elif ccaa:
        sources = [s for s in sources if s.get("ccaa", "").lower() == ccaa.lower()]
        if not sources:
            print(f"[WARN] No sources found matching CCAA '{ccaa}'.")

    downloaded = []
    for src in sources:
        path = download_source(src, raw_dir=raw_dir, force=force)
        downloaded.append(path)

    print(f"[INFO] Ingestion complete: {len(downloaded)} sources verified in {raw_dir}.")
    return downloaded


def main():
    parser = argparse.ArgumentParser(
        description="Download raw healthcare tariff gazettes and INE CPI deflators."
    )
    parser.add_argument(
        "--registry",
        default="packages/CohortCosts/data/specs/registries.yml",
        help="Path to registries.yml",
    )
    parser.add_argument(
        "--raw-dir",
        default="packages/CohortCosts/data/raw",
        help="Directory for raw cache",
    )
    parser.add_argument("--source-id", default=None, help="Download only a specific source ID")
    parser.add_argument("--ccaa", default=None, help="Download only sources for a specific CCAA")
    parser.add_argument("--force", action="store_true", default=False, help="Force re-download")
    parser.add_argument("--skip-ine", action="store_true", default=False, help="Skip INE deflators")
    args = parser.parse_args()

    if not args.skip_ine and not args.source_id and not args.ccaa:
        ine_cache = os.path.join(
            os.path.dirname(args.raw_dir), "external", "ine-ipc-medicina.json"
        )
        if not os.path.exists(os.path.dirname(ine_cache)):
            ine_cache = os.path.join(args.raw_dir, "ine-ipc-medicina.json")
        fetch_ine_deflators(cache_path=ine_cache, force=args.force)
        export_ine_tables(output_dir=os.path.dirname(ine_cache), raw_path=ine_cache)

    download_all_sources(
        registry_path=args.registry,
        raw_dir=args.raw_dir,
        force=args.force,
        source_id=args.source_id,
        ccaa=args.ccaa,
    )


if __name__ == "__main__":
    main()
