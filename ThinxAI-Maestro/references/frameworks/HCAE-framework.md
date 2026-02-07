# HCAE Framework Guidance

**Source:** [Human-Curated, AI-Enabled: A Framework for Reliable AI Deployment](https://zenodo.org/records/18368697)
**Author:** James (JD) Longmire
**DOI:** 10.5281/zenodo.18368697
**License:** CC BY 4.0
**Published:** January 25, 2026

---

## Overview

The HCAE (Human-Curated, AI-Enabled) framework addresses why enterprise AI projects fail at rates between 70-95%. These failures stem from **grounding-axis failures misdiagnosed as infrastructure problems**—not technical limitations.

> "AI systems lack access to the purposes they serve and the wholes their outputs enter."

The framework provides structured human oversight calibrated to task risk and domain complexity.

---

## Core Problem

Traditional AI deployment assumes that better models, more data, or improved infrastructure will solve reliability problems. HCAE identifies the real issue: **epistemic grounding**.

AI systems can:
- Transform inputs into outputs
- Pattern-match against training data
- Generate fluent, contextually appropriate text

AI systems cannot:
- Access the purposes behind requests
- Understand the broader context outputs enter
- Originate genuinely novel concepts
- Self-verify against reality

This is the **AIDK (AI Dunning-Kruger)** limitation: structural epistemic constraints that no amount of scaling resolves.

---

## The Four Deployment Tiers

HCAE is a **decision tool, not a maturity model**. Higher tiers aren't "better"—they're appropriate for different risk profiles.

### Tier 1: User-Curated (UCAE)

**Appropriate for:** Exploratory, low-stakes applications

| Aspect | Description |
|--------|-------------|
| **Human Role** | End user provides context, evaluates output |
| **AI Role** | Draft generation, brainstorming, summarization |
| **Oversight** | Informal, output-focused |
| **Risk Profile** | Low consequence if wrong |
| **Examples** | Personal writing, learning assistance, idea exploration |

### Tier 2: Professional-Curated (PCAE)

**Appropriate for:** Routine operational domain tasks

| Aspect | Description |
|--------|-------------|
| **Human Role** | Domain professional validates, edits, approves |
| **AI Role** | First drafts, template completion, data extraction |
| **Oversight** | Professional judgment, edit-before-publish |
| **Risk Profile** | Moderate—affects workflow efficiency |
| **Examples** | Report drafting, code review assistance, documentation |

### Tier 3: Expert-Curated (ECAE)

**Appropriate for:** High-consequence analytical work

| Aspect | Description |
|--------|-------------|
| **Human Role** | Domain expert originates, validates, decides |
| **AI Role** | Derives, cites, flags uncertainty |
| **Oversight** | Formal review gates, evidence requirements |
| **Risk Profile** | High—affects critical systems or decisions |
| **Examples** | Medical diagnosis support, legal analysis, security assessment |

**ThinxAI-Maestro operates at ECAE level.**

### Tier 4: Synthesis-Curated (SCAE)

**Appropriate for:** Domains requiring formal verification

| Aspect | Description |
|--------|-------------|
| **Human Role** | Multiple experts, formal consensus |
| **AI Role** | Tooling for verification, not judgment |
| **Oversight** | Formal proofs, multi-party review |
| **Risk Profile** | Critical—existential or irreversible consequences |
| **Examples** | Safety-critical systems, scientific publication, legal precedent |

---

## Tier Selection Criteria

Choose the appropriate tier based on:

| Factor | Lower Tier (UCAE/PCAE) | Higher Tier (ECAE/SCAE) |
|--------|------------------------|-------------------------|
| **Consequence of Error** | Inconvenience, rework | Harm, liability, irreversibility |
| **Domain Expertise Required** | General knowledge | Specialized training |
| **Verification Difficulty** | Easy to spot errors | Errors may be subtle |
| **Reversibility** | Easy to undo | Difficult or impossible |
| **Regulatory Environment** | Unregulated | Compliance required |

---

## HCAE Applied to ThinxAI-Maestro

### Why ECAE for IT Operations

IT Infrastructure & Operations meets ECAE criteria:

- **High consequence:** System changes affect availability
- **Expert knowledge:** Requires understanding of complex interdependencies
- **Subtle errors:** Misconfigurations may not manifest immediately
- **Partial reversibility:** Some changes are difficult to roll back
- **Compliance:** SOX, HIPAA, PCI-DSS requirements

### Implementation Mapping

| HCAE Principle | Maestro Implementation |
|----------------|------------------------|
| Human originates | Operators define policies, thresholds, approval gates |
| AI derives | Agents recommend actions based on evidence |
| Human validates | Guardrail feedback with risk acknowledgment |
| AI traces | Evidence objects link every conclusion to source |
| Human decides | Approval queue with blast radius, rollback info |
| AI executes | Only after explicit, informed consent |

### Agent Classification Under ECAE

| Agent Type | ECAE Role | Human Oversight |
|------------|-----------|-----------------|
| **Passive** | Observation, reporting | Review thresholds |
| **Active (Read)** | Query, correlate | Define data sources |
| **Active (Suggest)** | Recommend actions | Approve recommendations |
| **Active (Execute)** | Implement changes | Explicit approval with risk acknowledgment |

---

## Key Principles

### 1. Grounding-Axis Focus

The problem isn't AI capability—it's connecting AI to reality. Every output must trace to authoritative sources.

### 2. Epistemic Humility

AI doesn't "know"—it transforms inputs. Design systems that make this explicit.

### 3. Right-Sized Oversight

Don't apply SCAE overhead to brainstorming. Don't apply UCAE casualness to production changes.

### 4. Evidence-First

No conclusion without citation. No action without trace.

### 5. Human Accountability

Humans remain responsible. AI provides transparency, not absolution.

---

## Integration with AIDK Framework

HCAE operationalizes concepts from the AIDK (AI Dunning-Kruger) framework:

| AIDK Concept | HCAE Implementation |
|--------------|---------------------|
| **Origination vs Derivation** | Humans originate; AI derives with citation |
| **I∞ vs AΩ** | AI operates on representations, not reality |
| **Structural Limitation** | Tiers acknowledge what AI cannot do |
| **IDKE Risk** | Higher tiers add safeguards against overconfidence |

---

## References

- **Full Paper:** [zenodo.org/records/18368697](https://zenodo.org/records/18368697)
- **AIDK Framework:** [zenodo.org/records/18316059](https://zenodo.org/records/18316059)
- **GitHub Repository:** [github.com/jdlongmire/AI-Research](https://github.com/jdlongmire/AI-Research)

---

## Application Checklist

When designing a Maestro feature or agent:

- [ ] What tier is appropriate for this task?
- [ ] What human role is required?
- [ ] What evidence must the AI cite?
- [ ] What approval gate applies?
- [ ] How is the human informed of risk?
- [ ] How is the decision traced?
