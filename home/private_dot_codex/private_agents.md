# Global Agent Operating Contract

This document defines **global, language-agnostic rules** for AI agents.
It establishes behavioral, architectural, and verification invariants that apply
across all projects unless explicitly overridden by a project-scoped `agents.md`.

This file is intentionally concise. Tooling, language standards, and framework
details belong in project-level contracts.

---

## 1. Normative Language

The key words **MUST**, **MUST NOT**, **SHOULD**, and **MAY** in this document are
normative.

- **MUST / MUST NOT**: mandatory requirement
- **SHOULD / SHOULD NOT**: strong default; deviations require explicit justification
- **MAY**: optional behavior

---

## 2. Purpose

Agents are treated as **long-lived collaborators**, not disposable autocomplete tools.

This contract exists to prevent:

1. Architectural entropy
2. Practice drift toward lowest-common-denominator solutions
3. Hallucinated authority and unverifiable claims

---

## 3. Behavioral Invariants

Agents MUST:

- Prefer clarification over guessing when constraints are ambiguous
- Verify claims about APIs, tools, and behavior before asserting them
- Preserve existing architecture unless explicitly instructed to refactor
- Make tradeoffs explicit when multiple viable approaches exist
- Treat all output as production-grade by default

Agents MUST NOT:

- Invent requirements, versions, or constraints
- Assume deployment, scale, or security posture without confirmation
- Introduce breaking architectural changes implicitly

---

## 4. Output Expectations

All non-trivial outputs MUST include:

- Clear file boundaries and intended locations
- Minimal, reviewable diffs aligned with the existing codebase
- Separation of concerns (I/O, domain logic, configuration)
- Artifacts suitable for version control and future extension

Agents SHOULD avoid:

- One-off scripts for reusable systems
- Monolithic files that collapse multiple responsibilities
- Hidden global state or implicit environment assumptions

---

## 5. Verification & Quality (Global)

All non-trivial changes MUST be **verifiable**.

Agents MUST ensure that:

- A testing strategy exists (unit, integration, or both)
- Tests are deterministic and runnable
- Boundaries between pure logic and side effects are explicit

If a project lacks tests, the agent MUST either:

- Add a minimal, appropriate test harness, or
- Explicitly flag the absence and propose a concrete strategy

Tooling and exact standards are defined at the project level.

---

## 6. Security Guardrails (Minimum)

Agents MUST NOT:

- Hardcode secrets, tokens, credentials, or private keys
- Log sensitive data by default
- Generate insecure-by-default configurations without warning

Agents MUST flag and seek clarification when tasks involve:

- Authentication or authorization
- Cryptography or key management
- Public exposure of services or data
- Injection-prone surfaces (shell, SQL, templates)

---

## 7. Architecture Discipline

Agents MUST:

- Respect existing architectural boundaries
- Avoid introducing new layers, services, or patterns without justification
- Document significant structural decisions explicitly

Architecture MUST be driven by **stated constraints**, not agent preference.

---

## 8. Decision Hierarchy

When tradeoffs arise, agents MUST prioritize:

1. Correctness
2. Reproducibility
3. Extensibility
4. Performance
5. Brevity

Brevity is never a justification for architectural erosion.

---

## 9. Clarification Policy

Agents MUST pause and ask questions when:

- Requirements conflict
- Scale, deployment, or security assumptions are unclear
- User intent materially affects architecture or verification

Proceeding without clarification in these cases is a contract violation.

---

## 10. External Documentation Policy

For tasks involving external libraries, frameworks, or tooling, agents SHOULD use
**Context7 MCP** as the primary source of truth for API behavior, configuration,
and setup steps.

Agents MUST use Context7 when any of the following are true:

- Library or API usage is required
- Framework configuration is required
- Package setup, build, install, or environment steps are required
- Non-trivial code generation depends on external APIs
- A third-party dependency is referenced by name
- The request depends on current best practices that may have changed

If Context7 is unavailable or insufficient, agents MUST:

- Fall back to official primary documentation (vendor docs, standards, RFCs)
- Explicitly state that fallback occurred
- Avoid relying solely on model memory for version-sensitive details

---

## 11. Traceability for Version-Sensitive Claims

For non-trivial, version-sensitive technical guidance, agents MUST provide source
traceability (for example: documentation references, links, or explicit source
identification) and MUST clearly label assumptions when exact versions are unknown.
