#!/usr/bin/env python3
"""
build.py - Success Library HTML Generator

Reads metadata from JSON and code from .md files, generates index.html.

Usage:
    python build.py

The script reads:
    - metadata/success_library_index.json
    - code/{product}/{metric_id}.md files

And generates:
    - index.html (table-based interface with embedded code)
"""

import json
import re
import os
from datetime import datetime

# Configuration
METADATA_PATH = "metadata/success_library_index.json"
OUTPUT_PATH = "index.html"


def read_json(path):
    """Read and parse JSON file."""
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def read_file(path):
    """Read file contents."""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return None


def extract_code_blocks(markdown_content):
    """Extract SQL and PySpark code blocks from markdown."""
    sql_code = ""
    pyspark_code = ""

    if not markdown_content:
        return sql_code, pyspark_code

    # Pattern to match code blocks: ```language ... ```
    code_block_pattern = r'```(\w+)\n(.*?)```'
    matches = re.findall(code_block_pattern, markdown_content, re.DOTALL)

    for lang, code in matches:
        if lang.lower() == 'sql':
            sql_code = code.strip()
        elif lang.lower() == 'python':
            pyspark_code = code.strip()

    return sql_code, pyspark_code


def escape_html(text):
    """Escape HTML special characters."""
    if not text:
        return ""
    return (text
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&#39;"))


def generate_html(library_data, metrics_with_code):
    """Generate the HTML content."""

    lib_info = library_data.get("library_info", {})

    # Build table rows
    table_rows = []
    for metric in metrics_with_code:
        campaigns = ", ".join(metric.get("campaigns_using", []))
        source_tables = ", ".join(metric.get("source_tables", [])) or '<span class="empty">-</span>'
        business_def = metric.get("business_definition", "") or '<span class="empty">-</span>'
        lob = metric.get("line_of_business", "") or '<span class="empty">-</span>'
        staged = metric.get("staged_source", "") or '<span class="empty">-</span>'
        owner = metric.get("owner", "") or '<span class="empty">-</span>'

        row = f'''
            <tr class="metric-row" data-metric-id="{metric['metric_id']}"
                data-product="{metric.get('product', '')}"
                data-type="{metric.get('metric_type', '')}"
                data-pillar="{metric.get('pillar', '')}">
                <td class="col-id">{metric['metric_id']}</td>
                <td class="col-name">{metric['metric_name']}</td>
                <td class="col-definition">{business_def}</td>
                <td class="col-product">{metric.get('product', '')}</td>
                <td class="col-lob">{lob}</td>
                <td class="col-type"><span class="tag tag-type">{metric.get('metric_type', '')}</span></td>
                <td class="col-pillar"><span class="tag tag-pillar">{metric.get('pillar', '')}</span></td>
                <td class="col-campaigns">{campaigns}</td>
                <td class="col-grain">{metric.get('grain', '')}</td>
                <td class="col-owner">{owner}</td>
                <td class="col-version">{metric.get('version', '')}</td>
                <td class="col-actions">
                    <button class="btn-code" onclick="showCode('{metric['metric_id']}')">View Code</button>
                </td>
            </tr>'''
        table_rows.append(row)

    # Build code modals
    code_modals = []
    for metric in metrics_with_code:
        sql_escaped = escape_html(metric.get('sql_code', '-- No SQL code available'))
        pyspark_escaped = escape_html(metric.get('pyspark_code', '# No PySpark code available'))

        modal = f'''
        <div id="modal-{metric['metric_id']}" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>{metric['metric_id']} - {metric['metric_name']}</h2>
                    <button class="modal-close" onclick="closeModal('{metric['metric_id']}')">&times;</button>
                </div>
                <div class="modal-body">
                    <div class="metric-details">
                        <p><strong>Business Definition:</strong> {metric.get('business_definition', '') or 'To be defined'}</p>
                        <p><strong>Source Tables:</strong> {', '.join(metric.get('source_tables', [])) or 'To be defined'}</p>
                        <p><strong>Code File:</strong> <code>{metric.get('code_path', '')}</code></p>
                    </div>
                    <div class="code-tabs">
                        <button class="tab-btn active" onclick="switchTab('{metric['metric_id']}', 'sql')">SQL (Data Warehouse)</button>
                        <button class="tab-btn" onclick="switchTab('{metric['metric_id']}', 'pyspark')">PySpark (Hive)</button>
                    </div>
                    <div id="code-{metric['metric_id']}-sql" class="code-panel active">
                        <button class="btn-copy" onclick="copyCode('{metric['metric_id']}', 'sql')">Copy</button>
                        <pre><code>{sql_escaped}</code></pre>
                    </div>
                    <div id="code-{metric['metric_id']}-pyspark" class="code-panel">
                        <button class="btn-copy" onclick="copyCode('{metric['metric_id']}', 'pyspark')">Copy</button>
                        <pre><code>{pyspark_escaped}</code></pre>
                    </div>
                </div>
            </div>
        </div>'''
        code_modals.append(modal)

    # Get unique values for filters
    products = sorted(set(m.get('product', '') for m in metrics_with_code if m.get('product')))
    types = sorted(set(m.get('metric_type', '') for m in metrics_with_code if m.get('metric_type')))
    pillars = sorted(set(m.get('pillar', '') for m in metrics_with_code if m.get('pillar')))

    product_options = "\n".join(f'<option value="{p}">{p}</option>' for p in products)
    type_options = "\n".join(f'<option value="{t}">{t}</option>' for t in types)
    pillar_options = "\n".join(f'<option value="{p}">{p}</option>' for p in pillars)

    html = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Success Library</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f8f9fa;
            color: #333;
            line-height: 1.5;
        }}

        /* Header */
        .header {{
            background: #2c3e50;
            color: white;
            padding: 20px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        .header h1 {{
            font-size: 1.5rem;
            font-weight: 600;
        }}
        .header .version {{
            font-size: 0.85rem;
            opacity: 0.8;
        }}

        /* Container */
        .container {{
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }}

        /* Controls */
        .controls {{
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            flex-wrap: wrap;
            align-items: center;
        }}
        .search-box {{
            flex: 1;
            min-width: 250px;
        }}
        .search-box input {{
            width: 100%;
            padding: 10px 15px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }}
        .filters select {{
            padding: 10px 15px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: white;
            font-size: 14px;
            cursor: pointer;
        }}
        .result-count {{
            font-size: 14px;
            color: #666;
        }}

        /* Table */
        .table-container {{
            background: white;
            border-radius: 8px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            overflow-x: auto;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }}
        th {{
            background: #f1f3f4;
            padding: 12px 15px;
            text-align: left;
            font-weight: 600;
            color: #555;
            border-bottom: 2px solid #ddd;
            white-space: nowrap;
        }}
        td {{
            padding: 12px 15px;
            border-bottom: 1px solid #eee;
            vertical-align: middle;
        }}
        tr:hover {{
            background: #f8f9fa;
        }}
        .col-id {{
            font-family: monospace;
            font-weight: 600;
            color: #2c3e50;
        }}
        .col-name {{
            font-weight: 500;
        }}
        .col-definition {{
            max-width: 300px;
            font-size: 13px;
            color: #555;
        }}

        /* Tags */
        .tag {{
            display: inline-block;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: 500;
        }}
        .tag-type {{
            background: #e8f4fc;
            color: #1a73e8;
        }}
        .tag-pillar {{
            background: #fce8e8;
            color: #d93025;
        }}
        .empty {{
            color: #999;
            font-style: italic;
        }}

        /* Buttons */
        .btn-code {{
            background: #1a73e8;
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 13px;
        }}
        .btn-code:hover {{
            background: #1557b0;
        }}

        /* Modal */
        .modal {{
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }}
        .modal.active {{
            display: flex;
        }}
        .modal-content {{
            background: white;
            width: 90%;
            max-width: 900px;
            max-height: 85vh;
            border-radius: 8px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }}
        .modal-header {{
            background: #2c3e50;
            color: white;
            padding: 15px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        .modal-header h2 {{
            font-size: 1.1rem;
            font-weight: 600;
        }}
        .modal-close {{
            background: none;
            border: none;
            color: white;
            font-size: 24px;
            cursor: pointer;
            line-height: 1;
        }}
        .modal-body {{
            padding: 20px;
            overflow-y: auto;
        }}
        .metric-details {{
            margin-bottom: 20px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 4px;
        }}
        .metric-details p {{
            margin-bottom: 8px;
        }}
        .metric-details code {{
            background: #e8e8e8;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 13px;
        }}

        /* Code tabs */
        .code-tabs {{
            display: flex;
            gap: 5px;
            margin-bottom: 10px;
        }}
        .tab-btn {{
            padding: 8px 16px;
            border: 1px solid #ddd;
            background: #f1f3f4;
            cursor: pointer;
            border-radius: 4px 4px 0 0;
            font-size: 13px;
        }}
        .tab-btn.active {{
            background: #2d2d2d;
            color: white;
            border-color: #2d2d2d;
        }}
        .code-panel {{
            display: none;
            position: relative;
        }}
        .code-panel.active {{
            display: block;
        }}
        .code-panel pre {{
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 20px;
            border-radius: 0 4px 4px 4px;
            overflow-x: auto;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 13px;
            line-height: 1.5;
            margin: 0;
        }}
        .btn-copy {{
            position: absolute;
            top: 10px;
            right: 10px;
            background: #444;
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 3px;
            cursor: pointer;
            font-size: 12px;
            z-index: 10;
        }}
        .btn-copy:hover {{
            background: #555;
        }}

        /* Responsive */
        @media (max-width: 768px) {{
            .controls {{
                flex-direction: column;
            }}
            .search-box {{
                width: 100%;
            }}
        }}
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>Success Library</h1>
            <div class="version">{lib_info.get('version', '')} | Last updated: {lib_info.get('last_updated', '')}</div>
        </div>
    </div>

    <div class="container">
        <div class="controls">
            <div class="search-box">
                <input type="text" id="searchInput" placeholder="Search by metric ID, name, or campaign...">
            </div>
            <div class="filters">
                <select id="productFilter">
                    <option value="">All Products</option>
                    {product_options}
                </select>
                <select id="typeFilter">
                    <option value="">All Types</option>
                    {type_options}
                </select>
                <select id="pillarFilter">
                    <option value="">All Pillars</option>
                    {pillar_options}
                </select>
            </div>
            <div class="result-count">
                <span id="resultCount">{len(metrics_with_code)}</span> metrics
            </div>
        </div>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Metric ID</th>
                        <th>Name</th>
                        <th>Definition</th>
                        <th>Product</th>
                        <th>LOB</th>
                        <th>Type</th>
                        <th>Pillar</th>
                        <th>Campaigns</th>
                        <th>Grain</th>
                        <th>Owner</th>
                        <th>Version</th>
                        <th>Code</th>
                    </tr>
                </thead>
                <tbody id="metricsTable">
                    {"".join(table_rows)}
                </tbody>
            </table>
        </div>
    </div>

    <!-- Code Modals -->
    {"".join(code_modals)}

    <script>
        // Store code for copy functionality
        const codeData = {json.dumps({m['metric_id']: {'sql': m.get('sql_code', ''), 'pyspark': m.get('pyspark_code', '')} for m in metrics_with_code})};

        // Filter functionality
        function filterTable() {{
            const search = document.getElementById('searchInput').value.toLowerCase();
            const product = document.getElementById('productFilter').value;
            const type = document.getElementById('typeFilter').value;
            const pillar = document.getElementById('pillarFilter').value;

            const rows = document.querySelectorAll('.metric-row');
            let visibleCount = 0;

            rows.forEach(row => {{
                const text = row.textContent.toLowerCase();
                const rowProduct = row.dataset.product;
                const rowType = row.dataset.type;
                const rowPillar = row.dataset.pillar;

                const matchesSearch = !search || text.includes(search);
                const matchesProduct = !product || rowProduct === product;
                const matchesType = !type || rowType === type;
                const matchesPillar = !pillar || rowPillar === pillar;

                if (matchesSearch && matchesProduct && matchesType && matchesPillar) {{
                    row.style.display = '';
                    visibleCount++;
                }} else {{
                    row.style.display = 'none';
                }}
            }});

            document.getElementById('resultCount').textContent = visibleCount;
        }}

        // Modal functionality
        function showCode(metricId) {{
            document.getElementById('modal-' + metricId).classList.add('active');
            document.body.style.overflow = 'hidden';
        }}

        function closeModal(metricId) {{
            document.getElementById('modal-' + metricId).classList.remove('active');
            document.body.style.overflow = '';
        }}

        // Tab switching
        function switchTab(metricId, tab) {{
            // Update buttons
            const modal = document.getElementById('modal-' + metricId);
            modal.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            event.target.classList.add('active');

            // Update panels
            modal.querySelectorAll('.code-panel').forEach(panel => panel.classList.remove('active'));
            document.getElementById('code-' + metricId + '-' + tab).classList.add('active');
        }}

        // Copy functionality
        function copyCode(metricId, type) {{
            const code = codeData[metricId][type];
            navigator.clipboard.writeText(code).then(() => {{
                const btn = event.target;
                btn.textContent = 'Copied!';
                setTimeout(() => btn.textContent = 'Copy', 2000);
            }});
        }}

        // Close modal on outside click
        document.querySelectorAll('.modal').forEach(modal => {{
            modal.addEventListener('click', (e) => {{
                if (e.target === modal) {{
                    modal.classList.remove('active');
                    document.body.style.overflow = '';
                }}
            }});
        }});

        // Event listeners
        document.getElementById('searchInput').addEventListener('input', filterTable);
        document.getElementById('productFilter').addEventListener('change', filterTable);
        document.getElementById('typeFilter').addEventListener('change', filterTable);
        document.getElementById('pillarFilter').addEventListener('change', filterTable);
    </script>
</body>
</html>'''

    return html


def main():
    """Main build function."""
    print("Building Success Library index.html...")

    # Read metadata
    print(f"  Reading {METADATA_PATH}...")
    library_data = read_json(METADATA_PATH)

    # Load code for each metric
    metrics_with_code = []
    for metric in library_data.get("metrics", []):
        code_path = metric.get("code_path", "")
        print(f"  Loading {code_path}...")

        code_content = read_file(code_path)
        sql_code, pyspark_code = extract_code_blocks(code_content)

        metric_copy = metric.copy()
        metric_copy["sql_code"] = sql_code
        metric_copy["pyspark_code"] = pyspark_code
        metrics_with_code.append(metric_copy)

    # Generate HTML
    print(f"  Generating {OUTPUT_PATH}...")
    html = generate_html(library_data, metrics_with_code)

    # Write output
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"Done! Generated {OUTPUT_PATH} with {len(metrics_with_code)} metrics.")


if __name__ == "__main__":
    main()
