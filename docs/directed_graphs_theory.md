# Directed Graphs: Theoretical Background

## Overview

This document explains how NetworkBrokerage.jl handles directed graphs and the theoretical implications of the implementation choices. **Please read this carefully** before using the package with directed networks, as the implementation choices have important theoretical consequences.

## The Symmetrization Approach

### Burt's Original Formula

Burt's constraint measure treats directed networks through **automatic symmetrization**. The formula for proportional investment is:

```
p_ij = (a_ij + a_ji) / Σ_k(a_ik + a_ki)
```

where:
- `a_ij` is the edge weight from i to j
- `a_ji` is the edge weight from j to i
- The sum in the denominator ranges over all neighbors (both in-neighbors and out-neighbors)

This means **both directions contribute equally** to the constraint calculation.

### Why Symmetrization?

The symmetrization approach is used because:

1. **Burt's Design**: Built into the original formulation (Burt 1992, pp. 50-71, Appendix B)
2. **Industry Standard**: Both NetworkX and igraph use identical symmetrization
3. **Mathematical Proof**: Everett & Borgatti (2020) prove that transposing the adjacency matrix produces identical constraint values
4. **Practical**: Makes sense when relationships are fundamentally mutual

### What This Means

For directed graphs, the implementation treats constraint as arising from **mutual dependencies** rather than **unilateral investment choices**.

**Example:**
- If there's an edge 1→2 but not 2→1, the weight still counts toward node 1's constraint
- If there are edges both ways (1↔2), the weights sum: weight becomes (w_12 + w_21)
- Direction information is effectively lost through symmetrization

## When This Approach Is Appropriate

Use the standard implementation when:

### 1. Relationships are Bidirectional in Nature
- **Collaboration networks**: Working together creates mutual constraint
- **Communication networks**: Any contact indicates relationship salience
- **Friendship networks**: Usually implies mutuality
- **Alliance networks**: Partnerships create mutual dependencies

### 2. Direction Reflects Measurement Artifact
- **Survey data**: Non-response doesn't mean no relationship exists
- **Sampling**: Captures only some tie directions due to data collection limits
- **Recall errors**: Creating apparent asymmetry that doesn't reflect true relationship
- **Measurement timing**: Different observation times create apparent asymmetry

### 3. Network is Fully Reciprocated or Non-Reciprocated
- Everett & Borgatti (2020) prove results are identical to undirected formula
- Direction is mathematically irrelevant in these cases
- Constraint values will be the same regardless of how edges are oriented

## When You May Need Alternatives

### ⚠️ Choice-Based Theories

**If your theory concerns ego's unilateral resource allocation:**

**Examples:**
- Entrepreneurs deciding where to invest time
- Managers choosing collaboration partners
- Individuals allocating attention or resources
- Strategic partner selection

**Issue:** Symmetrization treats incoming ties equally with ego's choices. An incoming tie (j→i) affects node i's constraint the same as an outgoing tie (i→j), even though the theory may suggest only ego's outgoing choices matter.

**Solution:** May need out-edge only constraint (planned for future: `mode=:out` parameter)

### ⚠️ Influence/Prestige Networks

**If direction carries fundamental theoretical meaning:**

**Examples:**
- **Advice networks**: Advice-seeking vs. advice-giving involve different social processes
- **Citation networks**: Knowledge flow direction matters (who cites whom)
- **Information flow**: Direction indicates who influences whom
- **Hierarchical relations**: Superior-subordinate relationships are asymmetric

**Issue:** Symmetrization erases directional information. The constraint is the same whether i→j or j→i, losing theoretically important distinctions.

**Solution:** May need separate in-constraint and out-constraint measures

### ⚠️ Unidirectional Resource Flow

**If resources genuinely flow one direction:**

**Examples:**
- **Resource transfer networks**: Value flows from donor to recipient
- **Hierarchical reporting structures**: Authority flows downward
- **Monetary transactions**: Payment flows from buyer to seller
- **Knowledge transfer**: Expertise flows from expert to novice (when truly unidirectional)

**Issue:** Symmetrization may double-count or miscount flows that are genuinely unidirectional.

**Solution:** Directional variants needed

## Alternative Measures

If symmetrization doesn't match your theory, several alternatives exist:

### Option 1: Effective Size (Recommended Alternative)

**What it is:** Counts non-redundant alters in ego's network
- Formula (undirected): ES_i = N - (2t/n) where t = ties among alters, n = alters
- Simpler interpretation: "How many structurally non-redundant contacts does ego have?"

**Advantages for directed graphs:**
- **Clearer directional interpretation**: No symmetrization needed
- **Simpler**: Count unique out-neighbors minus their average out-degree
- **Less ambiguous**: Directly measures "how many non-redundant contacts ego actively maintains"
- **Empirical support**: Borgatti (1997) showed r=0.98 correlation with degree, suggesting constraint may be capturing network size more than structural holes

**When to use:**
- Your theory concerns ego's portfolio of distinct contacts
- You want to avoid symmetrization complications
- Simpler measure suffices for your research question

**Status:** Not yet implemented in NetworkBrokerage.jl (planned for v0.3.0)

### Option 2: Separate In-Constraint and Out-Constraint

**What it is:** Calculate constraint twice on different subgraphs

**Approach:**
```julia
# Conceptual approach (not yet implemented)
# Calculate out-constraint (ego's choices)
g_out = extract_out_edges(g)  # Keep only i→j edges
c_out = constraint(g_out, i)

# Calculate in-constraint (others' attention to ego)
g_in = extract_in_edges(g)    # Keep only j→i edges
c_in = constraint(g_in, i)

# Test which predicts outcomes
```

**When to use:**
- Direction matters theoretically (advice-seeking vs. giving)
- Exploratory analysis to see if direction affects results
- Testing competing theoretical mechanisms

**Advantages:**
- Preserves directional information
- Can test which direction matters empirically
- Standard constraint formula, just different input graphs

**Disadvantages:**
- More complex workflow
- Results not directly comparable to standard constraint
- Need theoretical justification for approach

### Option 3: Out-Edges Only (Pure Directional Constraint)

**What it is:** Constraint based solely on ego's outgoing ties

**Formula modifications:**
- Numerator: Use only w_ij (not w_ij + w_ji)
- Denominator: Sum over out-neighbors only (Σ_k w_ik where k ∈ outneighbors(i))
- Paths: Only follow directed paths (A→B→C, not A→B←C)

**When to use:**
- **Choice-based theories**: Entrepreneur allocating time/resources
- **Investment decisions**: Where ego chooses whom to invest in
- **Unilateral action**: Ego's choices independent of reciprocation

**Critical difference from standard approach:**
- Standard: Treats incoming tie 3→1 same as outgoing tie 1→3
- Out-only: 3→1 doesn't affect ego 1's constraint at all
- This fundamentally changes what's being measured

**Status:** Not currently in NetworkBrokerage.jl (planned for v0.3.0+ as `mode=:out`)

### Option 4: Weighted Reciprocity Approach

**What it is:** Distinguish reciprocated from non-reciprocated ties

**Approach (Everett & Borgatti 2020):**
1. Create weighted network where:
   - Reciprocated ties get weight 2
   - Non-reciprocated ties get weight 1
2. Apply standard constraint formula

**Advantages:**
- Preserves some directional information (reciprocity patterns)
- Mathematically proven equivalent to certain directional approaches
- More sophisticated than pure symmetrization

**Disadvantages:**
- Still fundamentally symmetric (doesn't distinguish i→j from j→i)
- More complex preprocessing
- Not implemented in standard packages

**When to use:**
- Reciprocity patterns matter theoretically
- You want to acknowledge asymmetry without full directional analysis
- Following Everett & Borgatti's (2020) recommendations

### Decision Guide

**Use this decision tree to choose the right approach:**

1. **Are relationships fundamentally bidirectional?**
   - Yes → Use standard constraint (current implementation)
   - No → Continue to 2

2. **Does your theory specifically concern ego's choices?**
   - Yes → Consider out-edges only (Option 3, future)
   - No → Continue to 3

3. **Is direction theoretically meaningful but uncertain which matters?**
   - Yes → Try separate in/out constraint (Option 2)
   - No → Continue to 4

4. **Do you just need a simpler, clearer measure?**
   - Yes → Use effective size (Option 1, future)
   - No → Consult with network methodologist

## The Theory-Implementation Mismatch

### Borgatti's Critique

**Important:** Borgatti (1997) identified that Burt's formulas are "ambiguous at best" and "shrouded in mathematical equations." There is a disconnect between:

- **What the theoretical language suggests**: Ego's "investment choices" and strategic allocation decisions
- **What the mathematics actually capture**: Mutual dependencies regardless of direction

This creates a mismatch between:
- **What the measure seems to capture** (ego's choices about where to invest)
- **What it actually captures** (mutual dependencies regardless of direction)

### Implications for Research

Researchers must be aware of this mismatch and carefully consider whether constraint, as standardly implemented, truly captures their theoretical construct. Simply using "constraint" because Burt's language sounds right may lead to:

- Results that don't align with theoretical predictions
- Incorrect interpretations of findings
- Difficulty relating results to theory
- Challenges in publication or peer review

### What To Do

1. **Read your theory carefully**: Does it actually concern mutual dependencies or unilateral choices?
2. **Check for directional language**: If your theory uses words like "ego chooses," "allocates," "decides," consider whether symmetrization fits
3. **Consider alternatives**: Effective size, separate in/out calculations, or directional modes
4. **Be explicit**: State clearly in your methods what the measure captures

## Critical Reporting Requirements

When publishing research using this package with directed graphs, your **methods section must state:**

### Required Elements:

1. **Software and version**: "NetworkBrokerage.jl version X.Y"
2. **Symmetrization approach**: "Directed edges were symmetrized using (w_ij + w_ji)"
3. **Theoretical alignment**: Explain why symmetrization matches your theory
4. **Interpretation**: State constraint measures mutual dependency, not unilateral investment

### Example Methods Section

> **Network Constraint Calculation**
>
> Network constraint was calculated using NetworkBrokerage.jl version 0.2.0 (Feltham, 2025). Following Burt's (1992) original formulation and standard implementations (NetworkX, igraph), directed edges were symmetrized by summing weights in both directions (w_ij + w_ji) when calculating proportional tie strengths. This approach treats ego's structural constraint as arising from mutual dependencies rather than ego's unilateral investment choices.
>
> This aligns with our theoretical model of collaboration networks where relationships are fundamentally reciprocal. In our context, any collaborative tie—regardless of who initiated it—creates constraint on both parties because: (1) collaboration requires mutual engagement and coordination, (2) both parties invest time and resources in the relationship, and (3) the presence of the relationship limits both parties' ability to broker between otherwise disconnected contacts. The symmetrization approach appropriately captures this mutual constraint rather than treating collaboration as a unilateral investment decision.
>
> Alternative approaches (e.g., out-edge only constraint) would be appropriate for networks where direction indicates unilateral resource allocation, but our theoretical framework explicitly treats collaboration as creating mutual rather than unilateral constraints.

### Why This Matters

Without explicit reporting:
- Readers may not understand what your measure captures
- Results may be misinterpreted
- Reviewers may question your methodological choices
- Other researchers cannot properly replicate your work
- Theoretical contributions may be unclear

## Summary Table

| Measure | Symmetrization | Direction Handling | Best For | Status |
|---------|---------------|-------------------|----------|--------|
| **Standard Constraint** | Yes (a_ij + a_ji) | Treats as mutual | Bidirectional relationships | Implemented |
| **Effective Size** | No | Can use out-edges only | Simple non-redundancy count | ⏳ Future (v0.3.0) |
| **Out-Constraint** | No | Out-edges only | Ego's choices/investments | ⏳ Future (v0.3.0+) |
| **In-Constraint** | No | In-edges only | Others' attention to ego | ⏳ Future (v0.3.0+) |
| **Separate In/Out** | No | Both separately | Exploratory directional analysis | Manual |
| **Weighted Reciprocity** | Partial | Reciprocated vs. not | Reciprocity patterns | Manual |

**Key insight from research**: Borgatti (1997) found effective size correlates r=0.98 with simple degree, suggesting constraint may be capturing network size more than structural holes. This raises questions about whether the complexity of constraint calculations is justified, especially for directed networks where implementation choices multiply.

## References

- **Burt, R.S. (1992).** *Structural Holes: The Social Structure of Competition*. Harvard University Press. (Original formulation)

- **Borgatti, S.P. (1997).** Structural holes: Unpacking Burt's redundancy measures. *Connections*, 20(1), 35-38. (Critique of ambiguity; effective size correlation)

- **Everett, M.G., & Borgatti, S.P. (2020).** Unpacking Burt's constraint measure. *Social Networks*, 62, 50-57. (Rigorous mathematical proof of symmetrization)

## Questions?

If you're unsure whether the standard symmetrization approach is appropriate for your research question, consider:

1. **Consult with a network methodologist**: Discuss your theoretical model and measurement choices
2. **Test sensitivity**: Run analyses with both undirected and directed versions to see if results differ substantially
3. **Explore effective size**: May provide clearer interpretation with fewer theoretical complications
4. **Wait for mode parameter**: Future versions (v0.3.0+) will offer optional directional modes
5. **Open an issue**: Share your use case on GitHub to help guide future development

## Getting Help

- **GitHub Issues**: [NetworkBrokerage.jl Issues](https://github.com/yourusername/NetworkBrokerage.jl/issues)
- **Theoretical questions**: Consult Borgatti (1997) and Everett & Borgatti (2020)
- **Implementation questions**: See package documentation and examples

---

**Bottom Line:** The standard implementation is theoretically sound **when relationships are mutual**. If your theory treats direction as fundamental to ego's strategic choices or resource allocation, carefully consider whether symmetrization captures your construct or whether alternatives are needed.
