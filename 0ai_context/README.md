# 0ai_context Directory Documentation

## 1. Why Prefix '0'
The leading zero (`0ai_context/`) ensures lexicographical sorting pins this directory to the top of file trees and file explorers. This makes documentation, architectural states, and reports immediately visible to developers and agents.

## 2. Why AGENTS.md at Root
Hermes Agent natively loads `./AGENTS.md` into the cached context tier on session startup. While `0ai_context/` contains comprehensive documentation for humans and multi-session continuity, Hermes does not auto-load subdirectories unless referenced. `AGENTS.md` serves as the authoritative, compact index and points directly to files in `0ai_context/`.

## 3. Workflow
1. **Launch Hermes**: Hermes automatically reads `AGENTS.md` into the context tier.
2. **Concise Tasks**: Keep task instructions brief. Do not paste bootstrap or mega-prompts.
3. **Reference Depth**: When deep architectural context is required, inspect `0ai_context/SEED.md` or `0ai_context/STATE.md`.
4. **Audit and Log**: Record major changes in sequential reports in `0ai_context/reports/NN-[task-slug].md`.
5. **Mandatory Appendix**: Conclude every report with an "MCP Evidence" appendix citing tool name, query parameters, and exact result counts.
