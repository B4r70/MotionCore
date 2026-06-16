#!/usr/bin/env bash
# MotionCore · dump-mac-swift.sh
# Concatenates all Swift sources from the project into a single text file
# Author: Bartosz Stryjewski
# Date: 16.06.2026

set -euo pipefail

PROJECT_DIR="${1:-$HOME/Developments/MotionCore}"
OUTPUT="${2:-$HOME/motioncore_swift_dump.txt}"

: > "$OUTPUT"

find "$PROJECT_DIR" -type f -name "*.swift" \
  -not -path "*/.build/*" \
  -not -path "*/DerivedData/*" \
  -not -path "*/.git/*" \
  | sort \
  | while IFS= read -r file; do
      rel="${file#"$PROJECT_DIR"/}"
      lines=$(wc -l < "$file" | tr -d ' ')
      {
        echo "// ============================================================"
        echo "// FILE:  $rel"
        echo "// LINES: $lines"
        echo "// ============================================================"
        cat "$file"
        echo
        echo
      } >> "$OUTPUT"
    done

echo "Done. $(grep -c '// FILE:' "$OUTPUT") files → $OUTPUT"
