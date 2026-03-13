#!/bin/bash

# ------------------------------------------------------------
# MotionCore – Swift Source Export
# Exportiert alle .swift Dateien rekursiv in eine Textdatei
# ------------------------------------------------------------

OUTPUT_FILE="SwiftSourcesDump.txt"

# Alte Datei löschen
rm -f "$OUTPUT_FILE"

echo "📦 Exporting Swift files into $OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "Generated at: $(date)" >> "$OUTPUT_FILE"
echo "Project root: $(pwd)" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"

# Alle Swift-Dateien rekursiv, sortiert
find . -type f -name "*.swift" | sort | while read -r FILE; do
    echo "" >> "$OUTPUT_FILE"
    echo "// ==================================================" >> "$OUTPUT_FILE"
    echo "// FILE: $FILE" >> "$OUTPUT_FILE"
    echo "// ==================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    cat "$FILE" >> "$OUTPUT_FILE"
done

echo ""
echo "✅ Done. Output written to $OUTPUT_FILE"
