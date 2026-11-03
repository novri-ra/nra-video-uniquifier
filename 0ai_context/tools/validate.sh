#!/usr/bin/env bash
H=0ai_context/HANDOFF.md
FAIL=0

# 1. All required files exist
for f in SEED.md STATE.md SKILLS.md CHANGELOG-map.md index.json HANDOFF.md reports/INDEX.md; do
  [ -f "0ai_context/$f" ] || { echo "MISSING_FILE: $f"; FAIL=1; }
done
ls 0ai_context/reports/[0-9][0-9]-audit.md >/dev/null 2>&1 || { echo "MISSING_AUDIT"; FAIL=1; }

# 2. HANDOFF size sanity
lines=$(wc -l < "$H")
if [ "$lines" -lt 500 ]; then echo "WARN: HANDOFF too short ($lines)"; fi
if [ "$lines" -gt 1200 ]; then echo "FAIL: HANDOFF too long ($lines)"; FAIL=1; fi

# 3. All 16 HANDOFF sections present
for s in "Project DNA" "Architecture" "Stack & Commands" "Dependency Graph" \
         "Critical Paths" "Data Models" "External Integrations" "Health Detail" \
         "Git Activity" "Findings Inventory" "Code Snippets" "Open Questions" \
         "Decision Log" "Constraints" "Glossary" "Run Manifest"; do
  grep -q "## [0-9]*\. .*$s" "$H" || { echo "MISSING_SECTION: $s"; FAIL=1; }
done

# 4. Snippets count
snips=$(grep -c "^### Snippet " "$H")
[ "$snips" -ge 10 ] || { echo "TOO_FEW_SNIPPETS: $snips (min 10)"; FAIL=1; }
[ "$snips" -le 25 ] || { echo "TOO_MANY_SNIPPETS: $snips (max 25)"; FAIL=1; }

# 5. Every finding has path:line
finding_rows=$(grep -E "^\| AUDIT-" "$H" | wc -l)
[ "$finding_rows" -ge 1 ] || echo "WARN: 0 findings in inventory"
grep -E "^\| AUDIT-" "$H" | grep -qvE '`[^`]+:[0-9]+`' && \
  { echo "FINDING_NO_PATH"; FAIL=1; }

# 6. Open questions present
qcount=$(awk '/^## 12\. Open Questions/,/^## 13\./' "$H" | grep -cE '^[0-9]+\.')
[ "$qcount" -ge 5 ] || { echo "TOO_FEW_QUESTIONS: $qcount"; FAIL=1; }

# 7. AI instructions block present
grep -q "AI INSTRUCTIONS — read before anything else" "$H" || \
  { echo "MISSING_AI_INSTRUCTIONS"; FAIL=1; }

# 8. No truncation markers
grep -nE '\.\.\. *(rest|more|omitted)|etc\.$' "$H" && { echo "TRUNCATION"; FAIL=1; }

# 9. No encoding drift
grep -lE 'â€|Ã[^a-z]|ï¿½' 0ai_context/*.md 0ai_context/reports/*.md 2>/dev/null && \
  { echo "ENCODING_DRIFT"; FAIL=1; }

# 10. SKILLS.md structural presence (not count-specific)
for sec in "2. Installed" "3. Built-in" "4. Behavior" "5. MCP" "10. Change"; do
  grep -qi "$sec" 0ai_context/SKILLS.md || { echo "SKILLS_MISSING: $sec"; FAIL=1; }
done

# 11. Report numbering valid
for f in 0ai_context/reports/[0-9][0-9]-*.md; do
  [ -f "$f" ] || continue
  basename "$f" | grep -qE '^[0-9]{2}-[a-z][a-z0-9-]*\.md$' || \
    { echo "BAD_REPORT_NAME: $f"; FAIL=1; }
done

# 12. No new modifications outside scope
comm -13 \
  <(sort 0ai_context/raw/git-status-before.txt) \
  <(git status --porcelain | sort) \
  | grep -vE '^(.. )?0ai_context/' | grep -q . && \
  { echo "SOURCE_MODIFIED"; FAIL=1; }

# 13. index.json parses
if command -v jq >/dev/null 2>&1; then
  jq -e '.commit and .stack and .reports' 0ai_context/index.json >/dev/null 2>&1 || { echo "INVALID_INDEX_JSON"; FAIL=1; }
elif command -v node >/dev/null 2>&1; then
  node -e "const d = require('./0ai_context/index.json'); if (!d.commit || !d.stack || !d.reports) process.exit(1);" || { echo "INVALID_INDEX_JSON"; FAIL=1; }
elif command -v python >/dev/null 2>&1; then
  python -c "import json; d = json.load(open('0ai_context/index.json')); assert d.get('commit') and d.get('stack') and d.get('reports')" || { echo "INVALID_INDEX_JSON"; FAIL=1; }
fi

# 14. CHANGELOG has at least one entry
grep -qE '^### [0-9]{4}-[0-9]{2}-[0-9]{2} — ' 0ai_context/CHANGELOG-map.md || \
  { echo "CHANGELOG_EMPTY"; FAIL=1; }

if [ $FAIL -ne 0 ]; then
  echo "=== VALIDATION FAILED ==="
  exit 1
fi
echo "=== VALIDATION PASSED ==="
