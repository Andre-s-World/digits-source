def format_symbol_list(symbol_rows):
    """Return the nm-style "address kind name" text read by generate-pinned-table.py."""
    lines, current = [], None
    for entry, address, kind, name in sorted(symbol_rows, key=lambda row: (row[0], row[3], row[1])):
        if entry != current:
            lines.append(f"Symbols for {entry}:")
            current = entry
        lines.append(f"{address:016x} {kind} {name}")
    return "\n".join(lines) + "\n"
