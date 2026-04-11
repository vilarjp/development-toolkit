# Council Debate Protocol

A structured multi-perspective debate for stress-testing high-stakes architectural decisions. Invoked automatically by the brainstorm skill when trigger conditions are met, or manually by the human.

## Advisor Archetypes

Six advisors examine the decision from different angles. Each is dispatched as a subagent (model: latest Sonnet, effort: medium).

| Advisor | Perspective | Signature Question |
|---------|------------|-------------------|
| **Pragmatic Engineer** | Delivery, maintainability, operational cost | "Can a mid-level engineer maintain this at 2 AM?" |
| **Architect Advisor** | System design, longevity, evolution | "How does this look in 2 years when requirements change?" |
| **Security Advocate** | Threat modeling, attack surface, compliance | "How can this be abused? What data is at risk?" |
| **Product Mind** | User impact, business value, adoption | "Does this solve the user's actual problem?" |
| **Devil's Advocate** | Contrarian, worst-case, hidden assumptions | "What is the strongest case against this?" |
| **The Thinker** | First principles, simplicity, problem framing | "Are we solving the right problem?" |

## Debate Protocol

### Round 1 — Position Statements (parallel, 3 at a time)

Dispatch advisors in two batches of 3. Each advisor receives:
- The brainstorm's problem statement, goals, non-goals, and constraints
- The 2-3 options generated in Phase 1.3
- Project context from Phase 0
- Instruction: "State your position on which option to choose and why. One paragraph maximum. Cite project context, not hypotheticals."

### Round 2 — Steel-Manning and Challenges (parallel, 3 at a time)

Each advisor receives all Round 1 positions and must:
1. **Steel-man** the strongest opposing view — restate it in its most compelling form before arguing against it
2. **Challenge** with evidence — claims must reference project context, codebase patterns, or stated constraints
3. **Concede** where appropriate — if another advisor's point changes your assessment, say so explicitly

### Synthesis — Orchestrator Consolidation

After both rounds, the orchestrator (brainstorm skill) synthesizes:

1. **Points of agreement** — where 4+ advisors converge
2. **Key tensions** — unresolved disagreements with strongest arguments from each side
3. **Concessions made** — positions that shifted during debate (strong signal)
4. **Decision record:**
   - Chosen direction and why
   - Key trade-offs accepted (with which advisor raised them)
   - Dissenting views acknowledged but not adopted (with reasoning)

## Evidence Requirements

- Every claim must cite project context, constraints, or observable codebase patterns
- "In my experience" and "generally speaking" are not evidence
- If an advisor cannot ground a claim in the current project, they must say so: "This is a general principle, not grounded in this codebase"

## Concession Tracking

When an advisor changes position:
```
CONCESSION: [Advisor name] shifted from [old position] to [new position]
REASON: [What evidence or argument caused the shift]
```

Concessions are high-signal — they indicate where the strongest arguments live.

## Output

The council debate produces a structured summary appended to the brainstorm document under a `## Council Debate` section, containing:
- Advisor positions (Round 1 summaries)
- Key challenges and steel-mans (Round 2 highlights)
- Concessions
- Synthesis and decision record
