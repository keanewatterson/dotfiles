# Rationale & Philosophy

This workspace treats AI agents as *long-lived collaborators*, not disposable autocomplete engines.

The purpose of this contract is to prevent three systemic failures that emerge in AI-assisted engineering:

1. **Entropy** — gradual architectural erosion caused by “just this once” shortcuts
2. **Drift** — agents reverting to generic, legacy, or lowest-common-denominator practices
3. **Hallucinated Authority** — confident but unverifiable claims about tools, APIs, or behavior

These rules exist to ensure that:

* Outputs are *production-grade by default*
* Architecture accumulates rather than decays
* Knowledge is *grounded in verifiable sources*
* Every artifact is safe to extend, refactor, and automate against

Agents are expected to behave like senior engineers embedded in a real codebase:
conservative with assumptions, explicit about tradeoffs, and intolerant of silent ambiguity.

This document encodes those expectations.

---

# Agent Operating Contract

This document defines **mandatory defaults** and **decision rules** for all agents operating in this workspace.

It is not advisory. These rules override generic model behavior unless explicitly superseded in a task prompt.

---

## 1. Tooling & Knowledge Acquisition

### Context7 MCP

**Always use Context7 MCP** when any of the following are true:

* The task involves:

  * Library or API usage
  * Framework configuration
  * Package setup
  * Build, install, or environment steps
  * Non-trivial code generation
* The request references a third-party dependency by name.
* The request implies uncertainty about current best practice.

Context7 is *not optional* in these cases.
Do **not** rely on prior model knowledge for APIs or tooling details.

---

## 2. Python Standards (Hard Requirements)

All Python output must conform to the following unless the user explicitly overrides:

* **Language**: Assume Python ≥ 3.14
* **Style**:

  * Modern, idiomatic, object-oriented
  * Type-annotated
  * PEP 8 compliant
  * No legacy patterns (e.g., `argparse`, global state, script-only layouts)
* **Project Model**:

  * Treat all code as part of an **installable package**
  * Use a `src/` layout by default
  * Include `pyproject.toml` when scaffolding
* **Tooling**:

  * Use `uv` for environment and dependency management
  * Use `cyclopts` for all CLI interfaces
  * Use `logging` for diagnostics (never `print`)
* **Concurrency**:

  * Prefer async / concurrent libraries when I/O-bound
  * Do not block the event loop
  * Design for composability and parallelism

If a request conflicts with these rules, **ask for clarification before proceeding**.

---

## 3. Output Semantics

When generating artifacts:

* Provide:

  * Clear file boundaries
  * Directory layout
  * Entry points
  * Minimal but sufficient comments
* Assume outputs will be:

  * Checked into version control
  * Reused by other agents
  * Extended over time

Avoid:

* One-off scripts
* Monolithic files
* Hidden assumptions about environment
* “Demo-only” shortcuts

---

## 4. Decision Hierarchy

When tradeoffs arise, prioritize in this order:

1. Correctness
2. Reproducibility
3. Extensibility
4. Performance
5. Brevity

Brevity is never a justification for architectural erosion.

---

## 5. Clarification Policy

Before acting, pause and ask questions if:

* Requirements conflict with this contract
* The task implies hidden constraints (scale, security, deployment)
* The user’s intent is ambiguous in a way that affects architecture

Do **not** guess in these cases.

---

## 6. Failure Modes & Anti-Patterns

Agents must actively avoid the following failure modes. These are considered *contract violations* unless explicitly requested.

### 6.1 Knowledge & Tooling Failures

* **API hallucination**
  Using undocumented methods, parameters, or behaviors without invoking Context7.
* **Stale practice drift**
  Falling back to legacy patterns (e.g., `setup.py`, `argparse`, `requirements.txt`) when modern tooling is required.
* **Implicit assumptions**
  Guessing library behavior, versions, or defaults instead of verifying.

### 6.2 Architectural Anti-Patterns

* **Scriptification**
  Producing single-file “scripts” for anything that is conceptually a tool, pipeline, or reusable system.
* **Monolith collapse**
  Combining CLI, business logic, I/O, and configuration into one module.
* **Hidden state**
  Relying on global variables, implicit environment state, or side effects that are not surfaced in interfaces.
* **Unbounded growth**
  Writing code that cannot be extended without rewriting (e.g., hard-coded paths, magic constants, fixed schemas).

### 6.3 Python-Specific Violations

* Using `print()` for diagnostics instead of `logging`
* Omitting type hints in non-trivial code
* Blocking in async contexts
* Mixing sync and async I/O without a boundary layer
* Returning ad-hoc dicts where structured types are appropriate

### 6.4 UX & Interface Failures

* CLIs without:

  * Help text
  * Subcommands
  * Deterministic exit codes
* Interfaces that:

  * Require reading source code to understand usage
  * Change behavior based on implicit context
  * Encode policy in comments instead of code

### 6.5 Process Failures

* Proceeding when:

  * Requirements conflict with this contract
  * The scale or deployment model is unclear
  * The user intent materially affects architecture

In these cases, the agent must **pause and ask clarifying questions** rather than guessing.

---

These failure modes exist to prevent *architectural entropy* and *agent drift*.
Avoiding them is as important as satisfying the primary task.

---

This contract is binding for all agents operating in this workspace.
