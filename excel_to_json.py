#!/usr/bin/env python3
"""
excel_to_json.py - Success Library Intake Processor

Processes Excel intake forms and updates the metadata JSON.

Features:
- Processes all .xlsx files in intake/pending/
- Creates backup before any changes
- Validates entries and checks for conflicts
- Shows summary and asks for confirmation
- Moves processed files to intake/processed/

Usage:
    python3 excel_to_json.py
"""

import json
import os
import shutil
from datetime import datetime
from pathlib import Path

try:
    import openpyxl
except ImportError:
    print("Error: openpyxl is required. Install with: pip3 install --user openpyxl")
    exit(1)

# Configuration
METADATA_PATH = Path("metadata/success_library_index.json")
PENDING_DIR = Path("intake/pending")
PROCESSED_DIR = Path("intake/processed")
BACKUP_DIR = Path("metadata/backups")

# Expected columns in the intake form (order matters for reading)
COLUMNS = [
    "action",
    "metric_id",
    "metric_name",
    "product",
    "line_of_business",
    "metric_type",
    "pillar",
    "business_definition",
    "source_tables",
    "staged_source",
    "grain",
    "owner",
    "campaigns_using",
]


def read_json(path):
    """Read and parse JSON file."""
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def write_json(path, data):
    """Write data to JSON file with pretty formatting."""
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def create_backup(source_path, backup_dir):
    """Create a timestamped backup of the JSON file."""
    backup_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"success_library_index_backup_{timestamp}.json"
    backup_path = backup_dir / backup_name
    shutil.copy2(source_path, backup_path)
    return backup_path


def parse_list_field(value):
    """Parse comma-separated string into list."""
    if not value:
        return []
    if isinstance(value, list):
        return value
    return [item.strip() for item in str(value).split(",") if item.strip()]


def parse_int_field(value):
    """Parse integer field, return None if empty."""
    if value is None or value == "":
        return None
    try:
        return int(float(value))
    except (ValueError, TypeError):
        return None


def read_intake_file(filepath):
    """Read an intake Excel file and return list of entries."""
    entries = []
    errors = []

    wb = openpyxl.load_workbook(filepath, data_only=True)

    # Find the Data Entry sheet (case-insensitive)
    ws = None
    for sheet_name in wb.sheetnames:
        if sheet_name.lower() == "data entry":
            ws = wb[sheet_name]
            break

    # Fallback: first sheet that's not Instructions
    if ws is None:
        for sheet_name in wb.sheetnames:
            if sheet_name.lower() != "instructions":
                ws = wb[sheet_name]
                break

    # Last resort: active sheet
    if ws is None:
        ws = wb.active

    # Read data starting from row 3 (row 1 = headers, row 2 = descriptions)
    for row_num, row in enumerate(ws.iter_rows(min_row=3, max_col=len(COLUMNS)), start=3):
        # Skip empty rows
        values = [cell.value for cell in row]
        if all(v is None or str(v).strip() == "" for v in values):
            continue

        # Skip example row marker
        if len(values) > 0 and values[0] and "example" in str(values[0]).lower():
            continue

        # Parse row into dict
        entry = {}
        for i, col_name in enumerate(COLUMNS):
            value = values[i] if i < len(values) else None

            # Clean up string values
            if isinstance(value, str):
                value = value.strip()
                if value == "":
                    value = None

            entry[col_name] = value

        # Validate required fields
        if not entry.get("action"):
            errors.append(f"Row {row_num}: 'action' is required")
            continue

        if entry["action"] not in ["new", "update"]:
            errors.append(f"Row {row_num}: 'action' must be 'new' or 'update', got '{entry['action']}'")
            continue

        if not entry.get("metric_id"):
            errors.append(f"Row {row_num}: 'metric_id' is required")
            continue

        # Parse special fields
        entry["source_tables"] = parse_list_field(entry.get("source_tables"))
        entry["campaigns_using"] = parse_list_field(entry.get("campaigns_using"))

        entry["_source_file"] = filepath.name
        entry["_source_row"] = row_num
        entries.append(entry)

    wb.close()
    return entries, errors


def validate_entries(entries, existing_metrics):
    """Validate entries against existing data."""
    errors = []
    warnings = []

    existing_ids = {m["metric_id"] for m in existing_metrics}
    seen_ids = set()

    for entry in entries:
        metric_id = entry["metric_id"]
        action = entry["action"]
        source = f"{entry['_source_file']} row {entry['_source_row']}"

        # Check for duplicates within intake
        if metric_id in seen_ids:
            errors.append(f"{source}: Duplicate metric_id '{metric_id}' in intake files")
            continue
        seen_ids.add(metric_id)

        # Validate action vs existence
        if action == "new" and metric_id in existing_ids:
            errors.append(f"{source}: metric_id '{metric_id}' already exists. Use 'update' instead.")
        elif action == "update" and metric_id not in existing_ids:
            errors.append(f"{source}: metric_id '{metric_id}' not found. Use 'new' instead.")

        # Validate required fields for new entries
        if action == "new":
            required_for_new = ["metric_name", "product", "metric_type", "pillar"]
            for field in required_for_new:
                if not entry.get(field):
                    errors.append(f"{source}: '{field}' is required for new metrics")

    return errors, warnings


def apply_changes(entries, library_data):
    """Apply intake entries to library data. Returns summary of changes."""
    metrics = library_data.get("metrics", [])
    metrics_by_id = {m["metric_id"]: m for m in metrics}

    added = []
    updated = []

    for entry in entries:
        action = entry["action"]
        metric_id = entry["metric_id"]

        # Remove internal tracking fields
        clean_entry = {k: v for k, v in entry.items() if not k.startswith("_")}
        del clean_entry["action"]

        if action == "new":
            # Generate code_path
            product = clean_entry.get("product", "UNKNOWN")
            clean_entry["code_path"] = f"code/{product}/{metric_id}.md"
            clean_entry["version"] = "v1.0"
            clean_entry["staged_source"] = clean_entry.get("staged_source", "")

            # Ensure all fields exist
            for field in ["line_of_business", "business_definition", "staged_source", "owner"]:
                if field not in clean_entry or clean_entry[field] is None:
                    clean_entry[field] = ""

            metrics.append(clean_entry)
            added.append(metric_id)

        elif action == "update":
            existing = metrics_by_id[metric_id]
            changes = []

            for field, value in clean_entry.items():
                # Skip empty values (keep existing)
                if value is None or value == "":
                    continue
                # Skip empty lists (keep existing)
                if isinstance(value, list) and len(value) == 0:
                    continue
                # Only update if value is different
                if value != existing.get(field):
                    old_val = existing.get(field)
                    existing[field] = value
                    changes.append(f"{field}: '{old_val}' → '{value}'")

            if changes:
                updated.append((metric_id, changes))

    library_data["metrics"] = metrics
    library_data["library_info"]["last_updated"] = datetime.now().strftime("%Y-%m-%d")

    return added, updated


def move_to_processed(filepath):
    """Move processed file to processed directory with timestamp."""
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    stem = filepath.stem
    new_name = f"{stem}_processed_{timestamp}.xlsx"
    dest = PROCESSED_DIR / new_name
    shutil.move(str(filepath), str(dest))
    return dest


def main():
    print("=" * 60)
    print("Success Library - Intake Processor")
    print("=" * 60)
    print()

    # Check for pending files
    PENDING_DIR.mkdir(parents=True, exist_ok=True)
    pending_files = list(PENDING_DIR.glob("*.xlsx"))

    if not pending_files:
        print(f"No intake files found in {PENDING_DIR}/")
        print("Place Excel files in this folder and run again.")
        return

    print(f"Found {len(pending_files)} intake file(s):")
    for f in pending_files:
        print(f"  - {f.name}")
    print()

    # Read all intake files
    all_entries = []
    all_errors = []

    for filepath in pending_files:
        print(f"Reading {filepath.name}...")
        entries, errors = read_intake_file(filepath)
        all_entries.extend(entries)
        all_errors.extend(errors)
        print(f"  Found {len(entries)} entries")

    print()

    if all_errors:
        print("ERRORS found in intake files:")
        for error in all_errors:
            print(f"  ✗ {error}")
        print()
        print("Please fix these errors and run again.")
        return

    if not all_entries:
        print("No valid entries found in intake files.")
        return

    # Load existing data
    print(f"Loading {METADATA_PATH}...")
    library_data = read_json(METADATA_PATH)
    existing_metrics = library_data.get("metrics", [])
    print(f"  Current metrics: {len(existing_metrics)}")
    print()

    # Validate
    print("Validating entries...")
    errors, warnings = validate_entries(all_entries, existing_metrics)

    if errors:
        print("VALIDATION ERRORS:")
        for error in errors:
            print(f"  ✗ {error}")
        print()
        print("Please fix these errors and run again.")
        return

    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"  ! {warning}")
        print()

    print("Validation passed.")
    print()

    # Preview changes
    added, updated = apply_changes(all_entries.copy(), json.loads(json.dumps(library_data)))

    print("=" * 60)
    print("SUMMARY OF CHANGES")
    print("=" * 60)
    print()

    if added:
        print(f"NEW METRICS ({len(added)}):")
        for metric_id in added:
            print(f"  + {metric_id}")
        print()

    if updated:
        print(f"UPDATED METRICS ({len(updated)}):")
        for metric_id, changes in updated:
            print(f"  ~ {metric_id}")
            for change in changes:
                print(f"      {change}")
        print()

    if not added and not updated:
        print("No changes to apply.")
        return

    print("=" * 60)
    print()

    # Confirm
    response = input("Apply these changes? (yes/no): ").strip().lower()

    if response != "yes":
        print("Cancelled. No changes made.")
        return

    print()

    # Create backup
    print("Creating backup...")
    backup_path = create_backup(METADATA_PATH, BACKUP_DIR)
    print(f"  Backup saved: {backup_path}")

    # Apply changes for real
    print("Applying changes...")
    library_data = read_json(METADATA_PATH)  # Re-read fresh
    apply_changes(all_entries, library_data)
    write_json(METADATA_PATH, library_data)
    print(f"  Updated: {METADATA_PATH}")

    # Move processed files
    print("Moving processed files...")
    for filepath in pending_files:
        dest = move_to_processed(filepath)
        print(f"  {filepath.name} → {dest.name}")

    print()
    print("=" * 60)
    print("DONE!")
    print("=" * 60)
    print()
    print("Next steps:")
    print("  1. Create code files for new metrics in code/{product}/{metric_id}.md")
    print("  2. Run: python3 build.py")
    print()


if __name__ == "__main__":
    main()
