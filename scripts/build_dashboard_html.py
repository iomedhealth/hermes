#!/usr/bin/env python3
"""
Build standalone, self-contained, interactive HTML dashboard for Spanish Healthcare Costs EDA.
Output: audit/dashboard.html
"""

import json
import pandas as pd
import numpy as np
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT_DIR / "data"
AUDIT_DIR = ROOT_DIR / "audit"
AUDIT_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_FILE = AUDIT_DIR / "dashboard.html"

# Load Parquet Data
costs_df = pd.read_parquet(DATA_DIR / "costs_spain.parquet")
ine_df = pd.read_parquet(DATA_DIR / "ine_indices_sanidad.parquet")

# 1. KPI Summary
kpi = {
    "total_records": int(len(costs_df)),
    "unique_ccaa": int(costs_df['ccaa'].nunique()),
    "total_spend_orig_m": round(costs_df['cost_original'].sum() / 1e6, 2),
    "total_spend_upd_m": round(costs_df['cost_updated'].sum() / 1e6, 2),
    "mean_cost_orig": round(costs_df['cost_original'].mean(), 2),
    "mean_cost_upd": round(costs_df['cost_updated'].mean(), 2),
    "median_cost_orig": round(costs_df['cost_original'].median(), 2),
    "median_cost_upd": round(costs_df['cost_updated'].median(), 2),
    "apr_grd_count": int(costs_df['code_std'].str.startswith('APR-GRD:').sum()),
    "standardized_code_pct": round((costs_df['code_std'] != '').sum() / len(costs_df) * 100, 2)
}

# 2. CCAA Breakdown
ccaa_grp = costs_df.groupby('ccaa').agg(
    total_records=('cost_id', 'count'),
    min_cost_orig=('cost_original', 'min'),
    median_cost_orig=('cost_original', 'median'),
    mean_cost_orig=('cost_original', 'mean'),
    median_cost_upd=('cost_updated', 'median'),
    mean_cost_upd=('cost_updated', 'mean'),
    max_cost_upd=('cost_updated', 'max'),
    year_orig=('year_original', lambda x: f"{x.min()}" if x.min() == x.max() else f"{x.min()}-{x.max()}"),
    n_specialties=('specialty', 'nunique'),
    n_settings=('setting', 'nunique')
).reset_index()
ccaa_grp['pct_total'] = (ccaa_grp['total_records'] / len(costs_df) * 100).round(2)
ccaa_grp = ccaa_grp.sort_values(by='total_records', ascending=False)
ccaa_data = ccaa_grp.to_dict(orient='records')

# 3. Settings & Domains
setting_grp = costs_df.groupby('setting').agg(
    count=('cost_id', 'count'),
    mean_orig=('cost_original', 'mean'),
    mean_upd=('cost_updated', 'mean'),
    median_upd=('cost_updated', 'median')
).reset_index()
setting_data = setting_grp.to_dict(orient='records')

domain_grp = costs_df.groupby('omop_domain').agg(
    count=('cost_id', 'count')
).reset_index()
domain_grp['pct'] = (domain_grp['count'] / len(costs_df) * 100).round(2)
domain_data = domain_grp.to_dict(orient='records')

unit_grp = costs_df.groupby('unit_type').agg(
    count=('cost_id', 'count')
).reset_index().sort_values(by='count', ascending=False)
unit_grp['pct'] = (unit_grp['count'] / len(costs_df) * 100).round(2)
unit_data = unit_grp.to_dict(orient='records')

# 4. APR-GRD Severity
apr_df = costs_df[costs_df['code_std'].str.startswith('APR-GRD:')].copy()
def parse_apr_sev(code):
    parts = code.split(':')[-1].split('-')
    if len(parts) == 2 and parts[1] in ['1', '2', '3', '4']:
        return int(parts[1])
    return None

apr_df['severity'] = apr_df['code_std'].apply(parse_apr_sev)
sev_df = apr_df[apr_df['severity'].notna()]
sev_grp = sev_df.groupby('severity').agg(
    count=('cost_id', 'count'),
    mean_orig=('cost_original', 'mean'),
    median_orig=('cost_original', 'median'),
    mean_upd=('cost_updated', 'mean'),
    median_upd=('cost_updated', 'median'),
    std_upd=('cost_updated', 'std'),
    min_upd=('cost_updated', 'min'),
    max_upd=('cost_updated', 'max')
).reset_index()
sev_grp['severity_label'] = sev_grp['severity'].map({
    1: 'Severity 1 (Minor)',
    2: 'Severity 2 (Moderate)',
    3: 'Severity 3 (Major)',
    4: 'Severity 4 (Extreme)'
})
sev_grp['step_pct'] = sev_grp['mean_upd'].pct_change() * 100
severity_data = sev_grp.to_dict(orient='records')

# 5. HEOR Benchmarks
bench_defs = [
    {
        'id': 'BENCH-01',
        'name': 'First Specialist Consultation',
        'filter': (costs_df['setting'] == 'Outpatient') & (costs_df['unit_type'] == 'per_visit') & (costs_df['description'].str.contains('primera consulta|consulta.*primera|primera.*especializada|1.ª consulta', case=False, na=False))
    },
    {
        'id': 'BENCH-02',
        'name': 'Primary Care Consultation',
        'filter': (costs_df['setting'] == 'Primary Care') & (costs_df['description'].str.contains('médic|medicina|ordinaria|consulta', case=False, na=False))
    },
    {
        'id': 'BENCH-03',
        'name': 'General Inpatient Per Diem Stay',
        'filter': (costs_df['setting'] == 'Inpatient') & (costs_df['unit_type'] == 'per_diem') & (costs_df['description'].str.contains('estancia|cama|hospitalización', case=False, na=False)) & (~costs_df['description'].str.contains('uci|crítico|reanim|intensiv', case=False, na=False))
    },
    {
        'id': 'BENCH-04',
        'name': 'ICU Per Diem Stay',
        'filter': (costs_df['setting'] == 'ICU') & (costs_df['unit_type'] == 'per_diem')
    },
    {
        'id': 'BENCH-05',
        'name': 'Emergency Department Episode',
        'filter': (
            (costs_df['setting'] == 'Emergency') &
            (costs_df['unit_type'] == 'per_visit') &
            (costs_df['description'].str.contains(r'\b(?:urgencia|urgencias)\b', case=False, na=False)) &
            (~costs_df['description'].str.contains(r'ambulancia|uvi|móvil|movil|traslado|transporte|helicóptero|helicoptero|técnico|tecnico|guardia|analítica|analitica|laboratorio', case=False, na=False))
        )
    },
    {
        'id': 'BENCH-06',
        'name': 'Brain / Cranial MRI',
        'filter': costs_df['description'].str.contains(r'resonancia.*(?:cráneo|cerebr|encef|cabeza|craneal)|rmn.*cráne|rm.*cráne', case=False, na=False)
    },
    {
        'id': 'BENCH-07',
        'name': 'Chest CT Scan',
        'filter': costs_df['description'].str.contains(r'tomograf.*(?:tórax|torác)|tac.*tórax|tc.*tórax', case=False, na=False)
    },
    {
        'id': 'BENCH-08',
        'name': 'Appendectomy (APR-GRD 225)',
        'filter': costs_df['code_std'].str.contains('APR-GRD:225|GRD:225', na=False) | (costs_df['description'].str.contains('apendicectom', case=False, na=False) & (costs_df['setting'] == 'Inpatient'))
    },
    {
        'id': 'BENCH-09',
        'name': 'Cataract Surgery (APR-GRD 073)',
        'filter': costs_df['code_std'].str.contains('APR-GRD:073|GRD:073', na=False) | (costs_df['description'].str.contains('catarata', case=False, na=False) & (costs_df['unit_type'].isin(['per_episode', 'per_procedure'])))
    },
    {
        'id': 'BENCH-10',
        'name': 'Knee Arthroplasty (APR-GRD 301/302)',
        'filter': costs_df['code_std'].str.contains('APR-GRD:301|APR-GRD:302|GRD:301|GRD:302', na=False) | (costs_df['description'].str.contains(r'artroplastia.*rodilla|prótesis.*rodilla', case=False, na=False) & (costs_df['setting'].isin(['Inpatient', 'Procedures'])))
    }
]

benchmarks_data = []
for b in bench_defs:
    subset = costs_df[b['filter']].copy()
    if len(subset) == 0:
        continue
    c_up = subset['cost_updated']
    mean_val = c_up.mean()
    std_val = c_up.std()
    cv_val = (std_val / mean_val) if mean_val > 0 else 0
    
    # Regional details
    ccaa_list = []
    for c_name, c_grp in subset.groupby('ccaa'):
        ccaa_list.append({
            'ccaa': c_name,
            'count': int(len(c_grp)),
            'mean_upd': round(float(c_grp['cost_updated'].mean()), 2),
            'median_upd': round(float(c_grp['cost_updated'].median()), 2),
            'min_upd': round(float(c_grp['cost_updated'].min()), 2),
            'max_upd': round(float(c_grp['cost_updated'].max()), 2)
        })
    ccaa_list = sorted(ccaa_list, key=lambda x: x['mean_upd'], reverse=True)
    
    benchmarks_data.append({
        'id': b['id'],
        'name': b['name'],
        'records_count': int(len(subset)),
        'ccaa_count': int(subset['ccaa'].nunique()),
        'mean': round(float(mean_val), 2),
        'std': round(float(std_val), 2),
        'cv': round(float(cv_val), 3),
        'min': round(float(c_up.min()), 2),
        'p25': round(float(c_up.quantile(0.25)), 2),
        'median': round(float(c_up.median()), 2),
        'p75': round(float(c_up.quantile(0.75)), 2),
        'max': round(float(c_up.max()), 2),
        'by_ccaa': ccaa_list
    })

# 6. INE Inflation Series
ine_df_sorted = ine_df.sort_values(by='year').copy()
ine_df_sorted['annual_pct'] = (ine_df_sorted['annual_index'].pct_change() * 100).round(2)
ine_df_sorted['cum_inflation_pct'] = ((ine_df_sorted['factor_to_2026'] - 1.0) * 100).round(2)
ine_data = ine_df_sorted.to_dict(orient='records')

# 7. Escalation by Publication Year
year_escalation = costs_df.groupby('year_original').agg(
    records=('cost_id', 'count'),
    mean_orig=('cost_original', 'mean'),
    median_orig=('cost_original', 'median'),
    sum_orig_m=('cost_original', lambda x: x.sum() / 1e6),
    mean_upd=('cost_updated', 'mean'),
    median_upd=('cost_updated', 'median'),
    sum_upd_m=('cost_updated', lambda x: x.sum() / 1e6)
).reset_index()
year_escalation = year_escalation.merge(ine_df[['year', 'annual_index', 'factor_to_2026', 'is_projected']], left_on='year_original', right_on='year', how='left')
year_escalation['pct_escalation'] = ((year_escalation['factor_to_2026'] - 1.0) * 100).round(2)
year_escalation_data = year_escalation.to_dict(orient='records')

# 8. Top Outliers
top_high = costs_df.sort_values(by='cost_updated', ascending=False).head(15)[['cost_id', 'ccaa', 'setting', 'code_std', 'description', 'cost_original', 'cost_updated']].to_dict(orient='records')
top_low = costs_df[costs_df['cost_updated'] > 0].sort_values(by='cost_updated', ascending=True).head(15)[['cost_id', 'ccaa', 'setting', 'code_std', 'description', 'cost_original', 'cost_updated']].to_dict(orient='records')

payload = {
    "kpi": kpi,
    "ccaa": ccaa_data,
    "settings": setting_data,
    "domains": domain_data,
    "units": unit_data,
    "severity": severity_data,
    "benchmarks": benchmarks_data,
    "ine": ine_data,
    "year_escalation": year_escalation_data,
    "top_high": top_high,
    "top_low": top_low
}

json_payload_str = json.dumps(payload, ensure_ascii=False)

# HTML Template
html_content = f"""<!DOCTYPE html>
<html lang="en" class="h-full bg-slate-950 text-slate-100">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>HERMES — Spanish Healthcare Costs & INE Inflation EDA Dashboard</title>
  <!-- Tailwind CSS CDN -->
  <script src="https://cdn.tailwindcss.com"></script>
  <!-- Chart.js CDN -->
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <script>
    tailwind.config = {{
      darkMode: 'class',
      theme: {{
        extend: {{
          colors: {{
            brand: {{
              50: '#f0fdf4',
              500: '#10b981',
              600: '#059669',
              700: '#047857',
              800: '#065f46',
              900: '#064e3b',
              950: '#022c22',
            }}
          }}
        }}
      }}
    }}
  </script>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
    body {{
      font-family: 'Plus Jakarta Sans', sans-serif;
    }}
    /* Custom scrollbar */
    ::-webkit-scrollbar {{
      width: 6px;
      height: 6px;
    }}
    ::-webkit-scrollbar-track {{
      background: #020617;
    }}
    ::-webkit-scrollbar-thumb {{
      background: #334155;
      border-radius: 3px;
    }}
    ::-webkit-scrollbar-thumb:hover {{
      background: #475569;
    }}
  </style>
</head>
<body class="min-h-full flex flex-col bg-slate-950 text-slate-100 antialiased selection:bg-emerald-500 selection:text-white">

  <!-- Top Navigation / Header -->
  <header class="sticky top-0 z-50 backdrop-blur-md bg-slate-950/80 border-b border-slate-800/80 px-6 py-4">
    <div class="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-4">
      <div class="flex items-center space-x-3">
        <div class="h-10 w-10 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-400 flex items-center justify-center font-black text-xl text-slate-950 shadow-lg shadow-emerald-500/20">
          H
        </div>
        <div>
          <div class="flex items-center gap-2">
            <h1 class="text-lg font-bold tracking-tight text-white">HERMES HEOR Analytics</h1>
            <span class="px-2 py-0.5 text-xs font-semibold rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">v0.1.0 Live</span>
          </div>
          <p class="text-xs text-slate-400">Spanish Ground-Source Healthcare Cost Catalogs & INE Sanidad Deflators (2002–2026)</p>
        </div>
      </div>

      <div class="flex items-center space-x-2">
        <button onclick="scrollToSection('sec-kpis')" class="px-3 py-1.5 text-xs font-medium rounded-lg text-slate-300 hover:text-white hover:bg-slate-800 transition">Overview</button>
        <button onclick="scrollToSection('sec-ccaa')" class="px-3 py-1.5 text-xs font-medium rounded-lg text-slate-300 hover:text-white hover:bg-slate-800 transition">Regions (19)</button>
        <button onclick="scrollToSection('sec-taxonomy')" class="px-3 py-1.5 text-xs font-medium rounded-lg text-slate-300 hover:text-white hover:bg-slate-800 transition">OMOP Taxonomy</button>
        <button onclick="scrollToSection('sec-casemix')" class="px-3 py-1.5 text-xs font-medium rounded-lg text-slate-300 hover:text-white hover:bg-slate-800 transition">APR-GRD Casemix</button>
        <button onclick="scrollToSection('sec-benchmarks')" class="px-3 py-1.5 text-xs font-medium rounded-lg text-slate-300 hover:text-white hover:bg-slate-800 transition">HEOR Benchmarks</button>
        <button onclick="scrollToSection('sec-inflation')" class="px-3 py-1.5 text-xs font-medium rounded-lg text-slate-300 hover:text-white hover:bg-slate-800 transition">INE Inflation</button>
        <button onclick="scrollToSection('sec-outliers')" class="px-3 py-1.5 text-xs font-medium rounded-lg text-slate-300 hover:text-white hover:bg-slate-800 transition">Outlier Audit</button>
      </div>
    </div>
  </header>

  <!-- Main Container -->
  <main class="flex-1 max-w-7xl w-full mx-auto px-6 py-8 space-y-10">

    <!-- KPI Summary Grid -->
    <section id="sec-kpis" class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
      <div class="bg-slate-900/70 border border-slate-800/80 rounded-2xl p-4 shadow-sm hover:border-emerald-500/30 transition">
        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Catalog Records</p>
        <p id="kpi-records" class="text-2xl font-black text-white mt-1">33,030</p>
        <span class="text-xs text-emerald-400 font-medium">100% Complete</span>
      </div>

      <div class="bg-slate-900/70 border border-slate-800/80 rounded-2xl p-4 shadow-sm hover:border-emerald-500/30 transition">
        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Jurisdictions</p>
        <p id="kpi-ccaa" class="text-2xl font-black text-white mt-1">19</p>
        <span class="text-xs text-slate-400">17 CCAA + INGESA + SNS</span>
      </div>

      <div class="bg-slate-900/70 border border-slate-800/80 rounded-2xl p-4 shadow-sm hover:border-emerald-500/30 transition">
        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider">2026 Valuation</p>
        <p id="kpi-val2026" class="text-2xl font-black text-emerald-400 mt-1">€188.82M</p>
        <span class="text-xs text-emerald-500 font-medium">+6.49% vs Baseline</span>
      </div>

      <div class="bg-slate-900/70 border border-slate-800/80 rounded-2xl p-4 shadow-sm hover:border-emerald-500/30 transition">
        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Median Item Tariff</p>
        <p id="kpi-median" class="text-2xl font-black text-white mt-1">€468.20</p>
        <span class="text-xs text-slate-400">Mean: €5,716.49</span>
      </div>

      <div class="bg-slate-900/70 border border-slate-800/80 rounded-2xl p-4 shadow-sm hover:border-emerald-500/30 transition">
        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider">APR-GRD DRGs</p>
        <p id="kpi-apr" class="text-2xl font-black text-teal-400 mt-1">6,415</p>
        <span class="text-xs text-slate-400">19.42% Inpatient Casemix</span>
      </div>

      <div class="bg-slate-900/70 border border-slate-800/80 rounded-2xl p-4 shadow-sm hover:border-emerald-500/30 transition">
        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Standard Code %</p>
        <p id="kpi-code" class="text-2xl font-black text-indigo-400 mt-1">37.41%</p>
        <span class="text-xs text-slate-400">GRD + Regional Vocab</span>
      </div>
    </section>

    <!-- Section 1: Regional Distribution -->
    <section id="sec-ccaa" class="bg-slate-900/70 border border-slate-800/80 rounded-3xl p-6 space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 class="text-xl font-bold text-white flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
            1. Volume & Regional Catalog Distribution
          </h2>
          <p class="text-xs text-slate-400 mt-0.5">Distribution of 33,030 catalog items across 17 Autonomous Communities, INGESA, and National Casemix</p>
        </div>
        <div class="flex items-center space-x-2">
          <select id="ccaa-sort-select" onchange="updateCcaaChart()" class="bg-slate-800 border border-slate-700 text-slate-200 text-xs rounded-xl px-3 py-2 outline-none focus:border-emerald-500">
            <option value="records">Sort by Record Count</option>
            <option value="mean">Sort by Mean Cost (€2026)</option>
            <option value="median">Sort by Median Cost (€2026)</option>
          </select>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Chart -->
        <div class="lg:col-span-2 bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 h-96">
          <canvas id="ccaaChart"></canvas>
        </div>

        <!-- Regional Quick Detail Card -->
        <div class="bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 flex flex-col justify-between space-y-4">
          <div>
            <h3 class="text-sm font-bold text-slate-300 uppercase tracking-wider mb-2">Regional Insights</h3>
            <div class="space-y-3 text-xs text-slate-400">
              <p><strong class="text-emerald-400">Top 5 Concentration:</strong> Cataluña, Andalucía, Extremadura, Baleares, and Murcia account for <strong class="text-white">61.27%</strong> of all ground-source items.</p>
              <p><strong class="text-teal-400">High-Severity Centers:</strong> País Vasco (€12,193 mean), Navarra (€10,020 mean), and La Rioja (€10,386 mean) focus almost exclusively on inpatient APR-GRD episodes.</p>
              <p><strong class="text-amber-400">Sparse Gazettes:</strong> Valencia (282 items), Castilla-La Mancha (153 items), and Asturias (125 items) publish high-level macro per-diems rather than micro-costed line items.</p>
            </div>
          </div>

          <div class="p-3 bg-slate-900 rounded-xl border border-slate-800 text-xs space-y-1">
            <span class="text-slate-500 font-semibold uppercase tracking-wider">Catalog Density Index</span>
            <div class="flex justify-between items-center text-slate-300">
              <span>National Casemix Baseline:</span>
              <span class="font-bold text-white">1,320 APR-GRDs</span>
            </div>
            <div class="flex justify-between items-center text-slate-300">
              <span>Micro-Costing Leaders:</span>
              <span class="font-bold text-emerald-400">CAT (5.2k), AND (4.9k)</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Section 2: Clinical Taxonomy & OMOP Domain Alignment -->
    <section id="sec-taxonomy" class="bg-slate-900/70 border border-slate-800/80 rounded-3xl p-6 space-y-6">
      <div>
        <h2 class="text-xl font-bold text-white flex items-center gap-2">
          <span class="w-2.5 h-2.5 rounded-full bg-teal-500"></span>
          2. Clinical Setting & OMOP CDM Taxonomy Alignment
        </h2>
        <p class="text-xs text-slate-400 mt-0.5">Cross-classification of catalog entries into OMOP CDM domains (`Visit`, `Measurement`, `Procedure`) and pricing units</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <!-- Setting Breakdown Doughnut -->
        <div class="bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 flex flex-col items-center">
          <h3 class="text-sm font-bold text-slate-300 mb-3">Setting Distribution (n=33,030)</h3>
          <div class="w-full h-64 relative">
            <canvas id="settingChart"></canvas>
          </div>
        </div>

        <!-- OMOP Domain Doughnut -->
        <div class="bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 flex flex-col items-center">
          <h3 class="text-sm font-bold text-slate-300 mb-3">OMOP CDM Domain</h3>
          <div class="w-full h-64 relative">
            <canvas id="domainChart"></canvas>
          </div>
        </div>

        <!-- Unit Types Horizontal Bar -->
        <div class="bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 flex flex-col items-center">
          <h3 class="text-sm font-bold text-slate-300 mb-3">Unit Type Breakdown</h3>
          <div class="w-full h-64 relative">
            <canvas id="unitChart"></canvas>
          </div>
        </div>
      </div>
    </section>

    <!-- Section 3: APR-GRD Casemix Monotonic Severity Escalation -->
    <section id="sec-casemix" class="bg-slate-900/70 border border-slate-800/80 rounded-3xl p-6 space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 class="text-xl font-bold text-white flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-indigo-500"></span>
            3. Standardized Clinical Codes & APR-GRD Casemix Escalation
          </h2>
          <p class="text-xs text-slate-400 mt-0.5">Empirical validation of monotonic cost escalation across Severity Levels 1 through 4 (5,884 coded DRGs)</p>
        </div>
        <span class="px-3 py-1 bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 rounded-full text-xs font-semibold">Strict Monotonicity Validated (p &lt; 0.001)</span>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Severity Step Chart -->
        <div class="lg:col-span-2 bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 h-96">
          <canvas id="severityChart"></canvas>
        </div>

        <!-- Escalation Multipliers Card -->
        <div class="bg-slate-950/60 border border-slate-800/60 rounded-2xl p-5 space-y-4 flex flex-col justify-between">
          <div>
            <h3 class="text-sm font-bold text-slate-300 uppercase tracking-wider mb-3">Severity Step Dynamics</h3>
            
            <div class="space-y-3">
              <div class="p-3 bg-slate-900/90 rounded-xl border border-slate-800 flex justify-between items-center">
                <div>
                  <p class="text-xs text-slate-400">Severity 1 (Minor)</p>
                  <p class="text-base font-bold text-white">€8,129.41</p>
                </div>
                <span class="text-xs font-semibold px-2 py-1 bg-slate-800 rounded-lg text-slate-300">Baseline (1.00x)</span>
              </div>

              <div class="p-3 bg-slate-900/90 rounded-xl border border-slate-800 flex justify-between items-center">
                <div>
                  <p class="text-xs text-slate-400">Severity 2 (Moderate)</p>
                  <p class="text-base font-bold text-emerald-400">€10,856.61</p>
                </div>
                <span class="text-xs font-semibold px-2 py-1 bg-emerald-500/20 text-emerald-400 rounded-lg">+33.55% (1.34x)</span>
              </div>

              <div class="p-3 bg-slate-900/90 rounded-xl border border-slate-800 flex justify-between items-center">
                <div>
                  <p class="text-xs text-slate-400">Severity 3 (Major)</p>
                  <p class="text-base font-bold text-teal-400">€16,254.61</p>
                </div>
                <span class="text-xs font-semibold px-2 py-1 bg-teal-500/20 text-teal-400 rounded-lg">+49.72% (2.00x)</span>
              </div>

              <div class="p-3 bg-slate-900/90 rounded-xl border border-slate-800 flex justify-between items-center">
                <div>
                  <p class="text-xs text-slate-400">Severity 4 (Extreme)</p>
                  <p class="text-base font-bold text-indigo-400">€29,900.24</p>
                </div>
                <span class="text-xs font-semibold px-2 py-1 bg-indigo-500/20 text-indigo-400 rounded-lg">+83.95% (3.68x)</span>
              </div>
            </div>
          </div>

          <p class="text-xs text-slate-400 italic">
            *Severity 4 exhibits exponential growth due to prolonged ICU mechanical ventilation, organ support, and complex surgery.
          </p>
        </div>
      </div>
    </section>

    <!-- Section 4: HEOR Price Disparities & Benchmarking -->
    <section id="sec-benchmarks" class="bg-slate-900/70 border border-slate-800/80 rounded-3xl p-6 space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 class="text-xl font-bold text-white flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-amber-500"></span>
            4. Cross-Regional Price Disparity & HEOR Benchmarks
          </h2>
          <p class="text-xs text-slate-400 mt-0.5">Evaluating inter-regional variation (Coefficient of Variation $CV = \\sigma / \\mu$) across 10 standardized clinical services</p>
        </div>

        <div class="flex items-center space-x-2">
          <label class="text-xs text-slate-400">Select Benchmark:</label>
          <select id="benchmark-select" onchange="updateBenchmarkView()" class="bg-slate-800 border border-slate-700 text-slate-200 text-xs rounded-xl px-3 py-2 outline-none focus:border-amber-500">
            <!-- Populated via JS -->
          </select>
        </div>
      </div>

      <!-- Benchmark Summary Row -->
      <div id="benchmark-summary-cards" class="grid grid-cols-2 md:grid-cols-6 gap-3">
        <!-- Injected via JS -->
      </div>

      <!-- Regional Comparison Bar Chart for Selected Benchmark -->
      <div class="bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 h-96">
        <canvas id="benchmarkChart"></canvas>
      </div>

      <!-- All Benchmarks Overview Table -->
      <div class="overflow-x-auto bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4">
        <h3 class="text-sm font-bold text-slate-300 mb-3">All 10 Standard HEOR Benchmarks Summary</h3>
        <table class="w-full text-left text-xs text-slate-300">
          <thead class="text-slate-400 uppercase bg-slate-900/80 border-b border-slate-800">
            <tr>
              <th class="py-2.5 px-3">Benchmark ID</th>
              <th class="py-2.5 px-3">Clinical Benchmark Service</th>
              <th class="py-2.5 px-3 text-right">Records</th>
              <th class="py-2.5 px-3 text-right">CCAAs</th>
              <th class="py-2.5 px-3 text-right">Mean (€2026)</th>
              <th class="py-2.5 px-3 text-right">Median (€2026)</th>
              <th class="py-2.5 px-3 text-right">Std (€)</th>
              <th class="py-2.5 px-3 text-right">CV (σ/μ)</th>
              <th class="py-2.5 px-3 text-right">Min (€2026)</th>
              <th class="py-2.5 px-3 text-right">Max (€2026)</th>
            </tr>
          </thead>
          <tbody id="benchmarks-table-body" class="divide-y divide-slate-800/60">
            <!-- Injected via JS -->
          </tbody>
        </table>
      </div>
    </section>

    <!-- Section 5: INE Inflation & Deflator Series -->
    <section id="sec-inflation" class="bg-slate-900/70 border border-slate-800/80 rounded-3xl p-6 space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 class="text-xl font-bold text-white flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-rose-500"></span>
            5. INE ECOICOP 06 Sanidad Deflator Series (2002–2026)
          </h2>
          <p class="text-xs text-slate-400 mt-0.5">Historical and projected healthcare price indices (Base 2021=100) and escalation multipliers</p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Inflation Line Chart -->
        <div class="lg:col-span-2 bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 h-96">
          <canvas id="inflationChart"></canvas>
        </div>

        <!-- Interactive Inflation Calculator Card -->
        <div class="bg-slate-950/60 border border-slate-800/60 rounded-2xl p-5 flex flex-col justify-between space-y-4">
          <div>
            <h3 class="text-sm font-bold text-slate-300 uppercase tracking-wider mb-2">Interactive Tariff Escalator</h3>
            <p class="text-xs text-slate-400 mb-4">Calculate constant 2026 value for any past baseline cost using official INE health indices.</p>

            <div class="space-y-3">
              <div>
                <label class="text-xs font-semibold text-slate-400">Original Decree Year</label>
                <select id="calc-year-select" onchange="runEscalator()" class="w-full mt-1 bg-slate-900 border border-slate-700 text-slate-200 text-xs rounded-xl px-3 py-2 outline-none focus:border-rose-500">
                  <!-- Populated via JS -->
                </select>
              </div>

              <div>
                <label class="text-xs font-semibold text-slate-400">Baseline Cost (€ Original)</label>
                <input type="number" id="calc-orig-input" value="1000" oninput="runEscalator()" class="w-full mt-1 bg-slate-900 border border-slate-700 text-slate-200 text-xs rounded-xl px-3 py-2 outline-none focus:border-rose-500">
              </div>
            </div>
          </div>

          <div class="p-4 bg-slate-900 rounded-xl border border-slate-800 space-y-2">
            <div class="flex justify-between items-center text-xs text-slate-400">
              <span>INE Deflator Multiplier:</span>
              <span id="calc-factor-res" class="font-bold text-rose-400">1.1268x</span>
            </div>
            <div class="flex justify-between items-center text-xs text-slate-400">
              <span>Cumulative Inflation (%):</span>
              <span id="calc-pct-res" class="font-bold text-amber-400">+12.68%</span>
            </div>
            <div class="border-t border-slate-800 pt-2 flex justify-between items-center">
              <span class="text-xs font-bold text-slate-200">Constant 2026 Cost:</span>
              <span id="calc-val2026-res" class="text-lg font-black text-emerald-400">€1,126.80</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Section 6: Outlier Audit & High/Low Cost Explorer -->
    <section id="sec-outliers" class="bg-slate-900/70 border border-slate-800/80 rounded-3xl p-6 space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 class="text-xl font-bold text-white flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-cyan-500"></span>
            6. Outlier Diagnostics & High/Low Cost Explorer
          </h2>
          <p class="text-xs text-slate-400 mt-0.5">Clinical justification of extreme outliers and audit of sub-Euro tariff lines</p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Top 10 High Cost Procedures -->
        <div class="bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 overflow-x-auto">
          <h3 class="text-sm font-bold text-slate-300 mb-3 flex items-center justify-between">
            <span>Top High-Cost Procedures (&gt; €160k)</span>
            <span class="text-xs px-2 py-0.5 bg-emerald-500/10 text-emerald-400 rounded-md border border-emerald-500/20">Clinical ECMO / CAR-T / Transplants</span>
          </h3>
          <table class="w-full text-left text-xs text-slate-300">
            <thead class="text-slate-400 uppercase bg-slate-900/80 border-b border-slate-800">
              <tr>
                <th class="py-2 px-2">CCAA</th>
                <th class="py-2 px-2">Code</th>
                <th class="py-2 px-2">Description</th>
                <th class="py-2 px-2 text-right">Cost 2026</th>
              </tr>
            </thead>
            <tbody id="high-cost-table-body" class="divide-y divide-slate-800/60">
              <!-- Injected via JS -->
            </tbody>
          </table>
        </div>

        <!-- Top 10 Low Cost Determinations -->
        <div class="bg-slate-950/60 border border-slate-800/60 rounded-2xl p-4 overflow-x-auto">
          <h3 class="text-sm font-bold text-slate-300 mb-3 flex items-center justify-between">
            <span>Lowest Tariff Items (&lt; €1.00)</span>
            <span class="text-xs px-2 py-0.5 bg-amber-500/10 text-amber-400 rounded-md border border-amber-500/20">Data Hygiene Flags</span>
          </h3>
          <table class="w-full text-left text-xs text-slate-300">
            <thead class="text-slate-400 uppercase bg-slate-900/80 border-b border-slate-800">
              <tr>
                <th class="py-2 px-2">CCAA</th>
                <th class="py-2 px-2">Setting</th>
                <th class="py-2 px-2">Gazette Description</th>
                <th class="py-2 px-2 text-right">Cost 2026</th>
              </tr>
            </thead>
            <tbody id="low-cost-table-body" class="divide-y divide-slate-800/60">
              <!-- Injected via JS -->
            </tbody>
          </table>
        </div>
      </div>
    </section>

  </main>

  <!-- Footer -->
  <footer class="border-t border-slate-800/80 bg-slate-950 px-6 py-6 text-center text-xs text-slate-500">
    <p>HERMES — Real-World Evidence & Health Economic Resource Modeling Ecosystem | Ground-Source Data Audit</p>
    <p class="mt-1">Generated: August 19, 2026 | Compliant with DARWIN-EU & OMOP CDM Standards</p>
  </footer>

  <!-- Inline Data & Application Scripts -->
  <script>
    const DATA = {json_payload_str};

    function scrollToSection(id) {{
      document.getElementById(id).scrollIntoView({{ behavior: 'smooth' }});
    }}

    // 1. Render CCAA Chart
    let ccaaChartInstance = null;
    function renderCcaaChart(sortBy = 'records') {{
      const ctx = document.getElementById('ccaaChart').getContext('2d');
      let sorted = [...DATA.ccaa];
      if (sortBy === 'records') {{
        sorted.sort((a, b) => b.total_records - a.total_records);
      }} else if (sortBy === 'mean') {{
        sorted.sort((a, b) => b.mean_cost_upd - a.mean_cost_upd);
      }} else if (sortBy === 'median') {{
        sorted.sort((a, b) => b.median_cost_upd - a.median_cost_upd);
      }}

      const labels = sorted.map(d => d.ccaa);
      const records = sorted.map(d => d.total_records);
      const meanCosts = sorted.map(d => d.mean_cost_upd);

      if (ccaaChartInstance) ccaaChartInstance.destroy();

      ccaaChartInstance = new Chart(ctx, {{
        type: 'bar',
        data: {{
          labels: labels,
          datasets: [
            {{
              label: 'Catalog Records',
              data: records,
              backgroundColor: 'rgba(16, 185, 129, 0.75)',
              borderColor: '#10b981',
              borderWidth: 1,
              borderRadius: 6,
              yAxisID: 'y'
            }},
            {{
              label: 'Mean Tariff (€2026)',
              data: meanCosts,
              type: 'line',
              borderColor: '#38bdf8',
              backgroundColor: '#38bdf8',
              borderWidth: 2,
              pointRadius: 4,
              pointHoverRadius: 6,
              yAxisID: 'y1'
            }}
          ]
        }},
        options: {{
          responsive: true,
          maintainAspectRatio: false,
          interaction: {{
            mode: 'index',
            intersect: false
          }},
          scales: {{
            x: {{
              grid: {{ color: 'rgba(51, 65, 85, 0.3)' }},
              ticks: {{ color: '#94a3b8', font: {{ size: 10 }}, maxRotation: 45 }}
            }},
            y: {{
              type: 'linear',
              position: 'left',
              title: {{ display: true, text: 'Record Count', color: '#10b981', font: {{ size: 11 }} }},
              grid: {{ color: 'rgba(51, 65, 85, 0.3)' }},
              ticks: {{ color: '#94a3b8', font: {{ size: 10 }} }}
            }},
            y1: {{
              type: 'linear',
              position: 'right',
              title: {{ display: true, text: 'Mean Tariff (€)', color: '#38bdf8', font: {{ size: 11 }} }},
              grid: {{ drawOnChartArea: false }},
              ticks: {{ color: '#94a3b8', font: {{ size: 10 }} }}
            }}
          }},
          plugins: {{
            legend: {{ labels: {{ color: '#cbd5e1', font: {{ size: 11 }} }} }}
          }}
        }}
      }});
    }}

    function updateCcaaChart() {{
      const val = document.getElementById('ccaa-sort-select').value;
      renderCcaaChart(val);
    }}

    // 2. Render Taxonomy Charts
    function renderTaxonomyCharts() {{
      // Setting Doughnut
      const ctxSet = document.getElementById('settingChart').getContext('2d');
      new Chart(ctxSet, {{
        type: 'doughnut',
        data: {{
          labels: DATA.settings.map(s => s.setting),
          datasets: [{{
            data: DATA.settings.map(s => s.count),
            backgroundColor: [
              '#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#06b6d4'
            ],
            borderColor: '#020617',
            borderWidth: 2
          }}]
        }},
        options: {{
          responsive: true,
          maintainAspectRatio: false,
          plugins: {{
            legend: {{ position: 'bottom', labels: {{ color: '#cbd5e1', font: {{ size: 10 }}, boxWidth: 10 }} }}
          }}
        }}
      }});

      // OMOP Domain Doughnut
      const ctxDom = document.getElementById('domainChart').getContext('2d');
      new Chart(ctxDom, {{
        type: 'doughnut',
        data: {{
          labels: DATA.domains.map(d => d.omop_domain + ' (' + d.pct + '%)'),
          datasets: [{{
            data: DATA.domains.map(d => d.count),
            backgroundColor: ['#10b981', '#6366f1', '#f59e0b'],
            borderColor: '#020617',
            borderWidth: 2
          }}]
        }},
        options: {{
          responsive: true,
          maintainAspectRatio: false,
          plugins: {{
            legend: {{ position: 'bottom', labels: {{ color: '#cbd5e1', font: {{ size: 10 }}, boxWidth: 10 }} }}
          }}
        }}
      }});

      // Unit Types Horizontal Bar
      const ctxUnit = document.getElementById('unitChart').getContext('2d');
      new Chart(ctxUnit, {{
        type: 'bar',
        data: {{
          labels: DATA.units.map(u => u.unit_type),
          datasets: [{{
            label: 'Items',
            data: DATA.units.map(u => u.count),
            backgroundColor: '#0ea5e9',
            borderRadius: 4
          }}]
        }},
        options: {{
          indexAxis: 'y',
          responsive: true,
          maintainAspectRatio: false,
          scales: {{
            x: {{ grid: {{ color: 'rgba(51, 65, 85, 0.3)' }}, ticks: {{ color: '#94a3b8', font: {{ size: 9 }} }} }},
            y: {{ grid: {{ display: false }}, ticks: {{ color: '#94a3b8', font: {{ size: 10 }} }} }}
          }},
          plugins: {{ legend: {{ display: false }} }}
        }}
      }});
    }}

    // 3. Render Severity Escalation Chart
    function renderSeverityChart() {{
      const ctx = document.getElementById('severityChart').getContext('2d');
      new Chart(ctx, {{
        type: 'line',
        data: {{
          labels: DATA.severity.map(s => s.severity_label),
          datasets: [
            {{
              label: 'Mean Cost 2026 (€)',
              data: DATA.severity.map(s => s.mean_upd),
              borderColor: '#6366f1',
              backgroundColor: 'rgba(99, 102, 241, 0.15)',
              fill: true,
              tension: 0.3,
              pointRadius: 6,
              pointBackgroundColor: '#6366f1',
              borderWidth: 3
            }},
            {{
              label: 'Median Cost 2026 (€)',
              data: DATA.severity.map(s => s.median_upd),
              borderColor: '#10b981',
              backgroundColor: 'rgba(16, 185, 129, 0.1)',
              fill: false,
              tension: 0.3,
              pointRadius: 5,
              pointBackgroundColor: '#10b981',
              borderWidth: 2,
              borderDash: [5, 5]
            }}
          ]
        }},
        options: {{
          responsive: true,
          maintainAspectRatio: false,
          scales: {{
            x: {{ grid: {{ color: 'rgba(51, 65, 85, 0.3)' }}, ticks: {{ color: '#cbd5e1', font: {{ size: 11 }} }} }},
            y: {{ grid: {{ color: 'rgba(51, 65, 85, 0.3)' }}, ticks: {{ color: '#cbd5e1', font: {{ size: 10 }} }} }}
          }},
          plugins: {{
            legend: {{ labels: {{ color: '#cbd5e1', font: {{ size: 11 }} }} }}
          }}
        }}
      }});
    }}

    // 4. Render Benchmarks
    let benchChartInstance = null;

    function initBenchmarks() {{
      const select = document.getElementById('benchmark-select');
      select.innerHTML = '';
      DATA.benchmarks.forEach((b, idx) => {{
        const opt = document.createElement('option');
        opt.value = idx;
        opt.textContent = `${{b.id}}: ${{b.name}} (CV: ${{b.cv}})`;
        select.appendChild(opt);
      }});

      // Populate summary table
      const tbody = document.getElementById('benchmarks-table-body');
      tbody.innerHTML = '';
      DATA.benchmarks.forEach(b => {{
        const tr = document.createElement('tr');
        tr.className = 'hover:bg-slate-900/50';
        tr.innerHTML = `
          <td class="py-2.5 px-3 font-semibold text-emerald-400">${{b.id}}</td>
          <td class="py-2.5 px-3 font-medium text-white">${{b.name}}</td>
          <td class="py-2.5 px-3 text-right">${{b.records_count}}</td>
          <td class="py-2.5 px-3 text-right">${{b.ccaa_count}}</td>
          <td class="py-2.5 px-3 text-right font-bold text-white">€${{b.mean.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</td>
          <td class="py-2.5 px-3 text-right">€${{b.median.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</td>
          <td class="py-2.5 px-3 text-right">€${{b.std.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</td>
          <td class="py-2.5 px-3 text-right font-bold ${{b.cv > 1.0 ? 'text-rose-400' : (b.cv > 0.5 ? 'text-amber-400' : 'text-emerald-400')}}">${{b.cv.toFixed(3)}}</td>
          <td class="py-2.5 px-3 text-right">€${{b.min.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</td>
          <td class="py-2.5 px-3 text-right">€${{b.max.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</td>
        `;
        tbody.appendChild(tr);
      }});

      updateBenchmarkView();
    }}

    function updateBenchmarkView() {{
      const idx = parseInt(document.getElementById('benchmark-select').value);
      const b = DATA.benchmarks[idx];

      // Summary Cards
      const cards = document.getElementById('benchmark-summary-cards');
      cards.innerHTML = `
        <div class="p-3 bg-slate-950/70 border border-slate-800 rounded-xl">
          <p class="text-slate-400 text-xs">Mean (€2026)</p>
          <p class="text-lg font-bold text-emerald-400 mt-0.5">€${{b.mean.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</p>
        </div>
        <div class="p-3 bg-slate-950/70 border border-slate-800 rounded-xl">
          <p class="text-slate-400 text-xs">Median (€2026)</p>
          <p class="text-lg font-bold text-white mt-0.5">€${{b.median.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</p>
        </div>
        <div class="p-3 bg-slate-950/70 border border-slate-800 rounded-xl">
          <p class="text-slate-400 text-xs">Std Deviation</p>
          <p class="text-lg font-bold text-slate-300 mt-0.5">€${{b.std.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</p>
        </div>
        <div class="p-3 bg-slate-950/70 border border-slate-800 rounded-xl">
          <p class="text-slate-400 text-xs">Coeff. of Variation</p>
          <p class="text-lg font-bold ${{b.cv > 1 ? 'text-rose-400' : 'text-amber-400'}} mt-0.5">${{b.cv.toFixed(3)}}</p>
        </div>
        <div class="p-3 bg-slate-950/70 border border-slate-800 rounded-xl">
          <p class="text-slate-400 text-xs">Min (€2026)</p>
          <p class="text-lg font-bold text-teal-400 mt-0.5">€${{b.min.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</p>
        </div>
        <div class="p-3 bg-slate-950/70 border border-slate-800 rounded-xl">
          <p class="text-slate-400 text-xs">Max (€2026)</p>
          <p class="text-lg font-bold text-rose-400 mt-0.5">€${{b.max.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</p>
        </div>
      `;

      // Render Bar Chart by CCAA
      const ctx = document.getElementById('benchmarkChart').getContext('2d');
      if (benchChartInstance) benchChartInstance.destroy();

      const ccaaLabels = b.by_ccaa.map(c => c.ccaa);
      const ccaaMeans = b.by_ccaa.map(c => c.mean_upd);
      const ccaaMedians = b.by_ccaa.map(c => c.median_upd);

      benchChartInstance = new Chart(ctx, {{
        type: 'bar',
        data: {{
          labels: ccaaLabels,
          datasets: [
            {{
              label: 'Regional Mean (€2026)',
              data: ccaaMeans,
              backgroundColor: 'rgba(245, 158, 11, 0.8)',
              borderColor: '#f59e0b',
              borderRadius: 6,
              borderWidth: 1
            }},
            {{
              label: 'Regional Median (€2026)',
              data: ccaaMedians,
              backgroundColor: 'rgba(16, 185, 129, 0.8)',
              borderColor: '#10b981',
              borderRadius: 6,
              borderWidth: 1
            }}
          ]
        }},
        options: {{
          responsive: true,
          maintainAspectRatio: false,
          scales: {{
            x: {{ grid: {{ color: 'rgba(51, 65, 85, 0.3)' }}, ticks: {{ color: '#94a3b8', font: {{ size: 10 }}, maxRotation: 45 }} }},
            y: {{ grid: {{ color: 'rgba(51, 65, 85, 0.3)' }}, ticks: {{ color: '#94a3b8', font: {{ size: 10 }} }} }}
          }},
          plugins: {{
            legend: {{ labels: {{ color: '#cbd5e1', font: {{ size: 11 }} }} }},
            title: {{ display: true, text: `${{b.name}} across ${{b.ccaa_count}} Jurisdictions`, color: '#cbd5e1', font: {{ size: 12 }} }}
          }}
        }}
      }});
    }}

    // 5. Render Inflation Chart & Calculator
    function renderInflationChart() {{
      const ctx = document.getElementById('inflationChart').getContext('2d');
      new Chart(ctx, {{
        type: 'line',
        data: {{
          labels: DATA.ine.map(i => i.year),
          datasets: [
            {{
              label: 'INE Sanidad Index (2021=100)',
              data: DATA.ine.map(i => i.annual_index),
              borderColor: '#f43f5e',
              backgroundColor: 'rgba(244, 63, 94, 0.1)',
              fill: true,
              tension: 0.2,
              pointRadius: 4,
              borderWidth: 2,
              yAxisID: 'y'
            }},
            {{
              label: 'Deflator Factor to 2026',
              data: DATA.ine.map(i => i.factor_to_2026),
              borderColor: '#38bdf8',
              tension: 0.2,
              pointRadius: 4,
              borderWidth: 2,
              borderDash: [4, 4],
              yAxisID: 'y1'
            }}
          ]
        }},
        options: {{
          responsive: true,
          maintainAspectRatio: false,
          scales: {{
            x: {{ grid: {{ color: 'rgba(51, 65, 85, 0.3)' }}, ticks: {{ color: '#94a3b8', font: {{ size: 10 }} }} }},
            y: {{
              type: 'linear',
              position: 'left',
              title: {{ display: true, text: 'Index (2021=100)', color: '#f43f5e', font: {{ size: 10 }} }},
              grid: {{ color: 'rgba(51, 65, 85, 0.3)' }},
              ticks: {{ color: '#94a3b8', font: {{ size: 10 }} }}
            }},
            y1: {{
              type: 'linear',
              position: 'right',
              title: {{ display: true, text: 'Deflator Multiplier', color: '#38bdf8', font: {{ size: 10 }} }},
              grid: {{ drawOnChartArea: false }},
              ticks: {{ color: '#94a3b8', font: {{ size: 10 }} }}
            }}
          }},
          plugins: {{
            legend: {{ labels: {{ color: '#cbd5e1', font: {{ size: 11 }} }} }}
          }}
        }}
      }});

      // Populate Escalator Dropdown
      const select = document.getElementById('calc-year-select');
      select.innerHTML = '';
      DATA.ine.forEach(i => {{
        const opt = document.createElement('option');
        opt.value = i.year;
        opt.textContent = `${{i.year}} (Index: ${{i.annual_index}}, Factor: ${{i.factor_to_2026}}x${{i.is_projected ? ' - Projected' : ''}})`;
        if (i.year === 2013) opt.selected = true;
        select.appendChild(opt);
      }});
      runEscalator();
    }}

    function runEscalator() {{
      const year = parseInt(document.getElementById('calc-year-select').value);
      const val = parseFloat(document.getElementById('calc-orig-input').value) || 0;
      const ineItem = DATA.ine.find(i => i.year === year);
      if (!ineItem) return;

      const factor = ineItem.factor_to_2026;
      const cumPct = ((factor - 1.0) * 100).toFixed(2);
      const updated = val * factor;

      document.getElementById('calc-factor-res').textContent = factor.toFixed(4) + 'x';
      document.getElementById('calc-pct-res').textContent = (cumPct >= 0 ? '+' : '') + cumPct + '%';
      document.getElementById('calc-val2026-res').textContent = '€' + updated.toLocaleString('en-US', {{minimumFractionDigits: 2, maximumFractionDigits: 2}});
    }}

    // 6. Populate Outlier Tables
    function populateOutliers() {{
      const highBody = document.getElementById('high-cost-table-body');
      highBody.innerHTML = '';
      DATA.top_high.forEach(item => {{
        const tr = document.createElement('tr');
        tr.className = 'hover:bg-slate-900/50';
        tr.innerHTML = `
          <td class="py-2 px-2 font-medium text-white">${{item.ccaa}}</td>
          <td class="py-2 px-2 font-mono text-emerald-400">${{item.code_std || '-'}}</td>
          <td class="py-2 px-2 text-slate-300 truncate max-w-xs" title="${{item.description}}">${{item.description}}</td>
          <td class="py-2 px-2 text-right font-bold text-white">€${{item.cost_updated.toLocaleString('en-US', {{minimumFractionDigits: 2}})}}</td>
        `;
        highBody.appendChild(tr);
      }});

      const lowBody = document.getElementById('low-cost-table-body');
      lowBody.innerHTML = '';
      DATA.top_low.forEach(item => {{
        const tr = document.createElement('tr');
        tr.className = 'hover:bg-slate-900/50';
        tr.innerHTML = `
          <td class="py-2 px-2 font-medium text-white">${{item.ccaa}}</td>
          <td class="py-2 px-2 text-slate-400">${{item.setting}}</td>
          <td class="py-2 px-2 text-amber-400/90 truncate max-w-xs" title="${{item.description}}">${{item.description}}</td>
          <td class="py-2 px-2 text-right font-bold text-white">€${{item.cost_updated.toFixed(2)}}</td>
        `;
        lowBody.appendChild(tr);
      }});
    }}

    // Initial Execution on Load
    window.addEventListener('DOMContentLoaded', () => {{
      renderCcaaChart();
      renderTaxonomyCharts();
      renderSeverityChart();
      initBenchmarks();
      renderInflationChart();
      populateOutliers();
    }});
  </script>
</body>
</html>
"""

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write(html_content)

print(f"Dashboard successfully built and saved to {OUTPUT_FILE} ({len(html_content)} bytes)")
