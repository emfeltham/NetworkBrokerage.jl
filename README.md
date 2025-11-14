# NetworkConstraint.jl

A Julia package for calculating network constraint and structural holes measures in social networks, based on the work of Ronald Burt (1992).

## Overview

Network constraint measures the extent to which a node's connections are redundant, indicating fewer structural holes and less brokerage opportunity. This package provides efficient implementations for calculating:

- **Network constraint**: Overall constraint on a node
- **Dyadic constraint**: Constraint imposed by a specific tie
- **Investment**: Proportional investment in network ties

## Installation

This package has not been registered (yet):

```julia
using Pkg
Pkg.develop(path="/Users/emf/.julia/dev/NetworkConstraint")
```

## Usage

### Basic Example

```julia
using NetworkConstraint
using Graphs

# Create a simple graph
g = cycle_graph(5)

# Calculate constraint for a node
c = constraint(g, 1)

# Calculate dyadic constraint between two nodes
dc = dyadconstraint(g, 1, 2)
```

### Weighted Graphs

The package automatically handles weighted graphs:

```julia
using SimpleWeightedGraphs

# Create a weighted graph
wg = SimpleWeightedGraph(5)
add_edge!(wg, 1, 2, 2.0)
add_edge!(wg, 1, 3, 1.5)
add_edge!(wg, 2, 3, 1.0)

# Constraint calculations work the same way
c = constraint(wg, 1)
dc = dyadconstraint(wg, 1, 2)
```

### Directed Graphs

The package fully supports directed graphs with flexible mode parameter for different theoretical frameworks:

```julia
using Graphs

# Create a directed graph
g = DiGraph(5)
add_edge!(g, 1, 2)  # 1→2
add_edge!(g, 3, 1)  # 3→1
add_edge!(g, 4, 1)  # 4→1

# Default mode=:both uses symmetrization (standard approach)
c_both = constraint(g, 1)  # or explicitly: constraint(g, 1; mode=:both)

# mode=:out considers only outgoing edges (ego's choices)
c_out = constraint(g, 1; mode=:out)

# mode=:in considers only incoming edges (others' attention to ego)
c_in = constraint(g, 1; mode=:in)

# Also works with weighted directed graphs
using SimpleWeightedGraphs
wdg = SimpleWeightedDiGraph(5)
add_edge!(wdg, 1, 2, 2.0)
add_edge!(wdg, 2, 3, 1.5)

# Use mode parameter based on your theory
c = constraint(wdg, 1; mode=:out)  # Ego's investment decisions
```

#### Mode Parameter

The `mode` parameter controls how directed edges are treated:

**`mode=:both`** (default) - Symmetrization:
```
p_ij = (w_ij + w_ji) / Σ_k (w_ik + w_ki)
```
- Both directions contribute equally
- Standard Burt formula, matches NetworkX/igraph
- Use for mutual relationships (collaboration, communication)

**`mode=:out`** - Out-edges only:
```
p_ij = w_ij / Σ_k w_ik (k ∈ outneighbors)
```
- Only ego's outgoing ties
- Use for choice-based theories (resource allocation, strategic decisions)
- Measures ego's unilateral investment decisions

**`mode=:in`** - In-edges only:
```
p_ij = w_ji / Σ_k w_ki (k ∈ inneighbors)
```
- Only incoming ties to ego
- Use for prestige/popularity theories
- Measures others' attention to ego

**Implementation follows standard practice:**
- Matches NetworkX and igraph implementations
- Based on Burt's original formula with automatic symmetrization
- Both edge directions (i→j and j→i) contribute equally to constraint
- Treats relationships as fundamentally mutual dependencies

**Asymmetric ties:** When edges exist in only one direction, the formula naturally handles the asymmetry by setting the missing edge weight to 0.

#### Important Theoretical Considerations

**When this approach is appropriate:**
- Relationships are fundamentally bidirectional (collaboration, friendship, communication)
- Direction differences reflect measurement artifact rather than theoretical substance
- Networks are fully reciprocated or fully non-reciprocated
- Theory treats constraint as arising from mutual dependencies

**When you may need alternatives:**
- Your theory specifically concerns **ego's unilateral choices** (e.g., entrepreneurs allocating time/resources) → Consider future out-edge only mode
- Direction carries **fundamental theoretical meaning** (e.g., advice-seeking vs. advice-giving, citation flows) → May need separate in/out constraint measures
- **Resource flows are genuinely unidirectional** → Symmetrization may not capture your theoretical construct

**Critical:** The implementation treats constraint as arising from **mutual dependencies** rather than **unilateral investment choices**. If your theory uses language like "ego chooses" or "allocates resources," carefully consider whether symmetrization aligns with your theoretical model.

**For detailed theoretical discussion**, see [`docs/directed_graphs_theory.md`](docs/directed_graphs_theory.md), which covers:
- When symmetrization is/isn't appropriate
- Alternative measures for different research questions
- The theory-implementation mismatch identified by Borgatti (1997)
- Critical reporting requirements for publications

#### When Publishing Research

If you use this package with directed graphs in published research, your methods section should:

1. State that you used NetworkConstraint.jl version X.Y
2. Explicitly mention that directed edges were symmetrized using (w_ij + w_ji)
3. Explain how this aligns with your theoretical model
4. Clarify that the measure captures mutual dependency rather than unilateral investment

See [`docs/directed_graphs_theory.md`](docs/directed_graphs_theory.md) for an example methods section you can adapt.

### Alternative Measures

If the standard symmetrization approach doesn't match your research question:

**Effective Size** (planned for v0.3.0): Simpler measure with clearer directional interpretation
- Counts non-redundant alters without symmetrization
- Can be calculated using only out-neighbors for directed graphs
- Borgatti (1997) found r=0.98 correlation with constraint

**Directional Modes**
```julia
constraint(g, i; mode=:both)  # Default (symmetrization)
constraint(g, i; mode=:out)   # Out-edges only
constraint(g, i; mode=:in)    # In-edges only
```

All three functions (`constraint`, `dyadconstraint`, `investment`) support the `mode` parameter.

**Manual Approaches**: Calculate constraint on edge-filtered subgraphs
- Extract out-edges only and calculate constraint (ego's choices)
- Extract in-edges only and calculate constraint (others' attention to ego)
- Compare which direction predicts your outcomes

For more details, see the [Alternative Measures section](docs/directed_graphs_theory.md#alternative-measures) in the theoretical documentation.

## API Reference

### `constraint(g, i)`

Calculate the total network constraint on node `i`.

**Formula:** `C_i = �_j c_ij = �_j (p_ij + �_q`j p_iq � p_qj)�`

where:
- `p_ij` is the proportional investment from node i to node j
- The sum is over all neighbors j of node i

**Returns:** `Float64` - Total constraint (0 d C_i d degree(i))

**Interpretation:**
- Higher values indicate fewer structural holes and less brokerage opportunity
- Lower values indicate more structural holes and greater social capital

### `dyadconstraint(g, i, j)`

Calculate the dyadic constraint imposed by the tie between nodes `i` and `j`.

**Formula:** `c_ij = (p_ij + �_q p_iq � p_qj)�`

**Returns:** `Float64` - Dyadic constraint (0 d c_ij d 1)

**Note:** Can also accept an edge object: `dyadconstraint(g, edge)`

### `investment(g, i, j)`

Calculate the proportional investment from node `i` to node `j`.

**Formula (unweighted):** `p_ij = (e_ij + e_ji) / �_k (e_ik + e_ki)`

**Formula (weighted):** `p_ij = (w_ij + w_ji) / �_k (w_ik + w_ki)`

**Returns:** `Float64` - Investment proportion (0 d p_ij d 1)

### `investment_sum(g, i, j)`

Calculate the indirect investment from node `i` to node `j` through mutual neighbors.

**Formula:** `�_q`j p_iq � p_qj`

**Returns:** `Float64` - Sum of indirect investments

## Implementation Details

- Automatically detects and handles both weighted and unweighted graphs
- Uses memoization to optimize constraint calculations from O(d�) to O(d�)
- Handles edge cases: isolated nodes, disconnected components
- All calculations follow Burt's original formulations

## Testing

Run the test suite:

```julia
using Pkg
Pkg.test("NetworkConstraint")
```

The test suite includes:
- Various graph types (star, cycle, path, complete graphs)
- Edge cases (isolated nodes, non-neighbors)
- Weighted and unweighted graphs
- Mathematical properties (symmetry, constraint decomposition)

## References

- Burt, R.S. (1992). *Structural Holes: The Social Structure of Competition*. Cambridge, MA: Harvard University Press.

- Borgatti, S.P. (1997). Structural holes: Unpacking Burt's redundancy measures. *Connections*, 20(1), 35-38.

- Everett, M.G., & Borgatti, S.P. (2020). Unpacking Burt's constraint measure. *Social Networks*, 62, 50-57.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

Eric Martin Feltham <eric.feltham@aya.yale.edu>
