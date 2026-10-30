# Session Reports Policy

## 1. Naming Convention
- All session reports must follow the format: `NN-[task-slug].md`
- `NN` is a zero-padded, strictly sequential integer: `01-`, `02-`, `21-`, etc.
- No dates or timestamps in report filenames (timestamps belong inside the report header).
- Never rename existing past reports, to preserve historical citations and git history.

## 2. Archival Policy
- Reports correspond to the current development cycle.
- Upon major releases or version tags (e.g. `archive/v1.0/`), reports may be archived into version subfolders if necessary, while preserving sequential numbering.

## 3. Mandatory MCP Evidence Appendix
Every session report MUST end with an `MCP Evidence` appendix with:
- Exact MCP tool called (e.g. `codebase-memory-mcp:search_graph`)
- Input arguments/filters used
- Exact result count returned
- Explicit verification: `verified` or `unverified`
