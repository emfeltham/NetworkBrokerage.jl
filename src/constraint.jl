# constraint.jl

# ============================================================================
# CONSTRAINT - UNIFIED PUBLIC API
# ============================================================================

"""
        constraint(g, i; mode=:both)

## Description

Network constraint for node i as defined in Burt (1992, 1993).

Formula: C_i = Σ_j c_ij = Σ_j (p_ij + Σ_q≠j p_iq × p_qj)²

where:
- p_ij is the proportional investment from i to j
- The sum is over all neighbors j of node i

Higher constraint indicates fewer structural holes and less brokerage opportunity.
Lower constraint indicates more structural holes and greater social capital.

## Mode Parameter for Directed Graphs

The `mode` parameter controls how directed edges are treated:

**`mode=:both`** (default): Symmetrization following Burt's original formula
- Both i→j and j→i contribute equally to constraint
- Investment: p_ij = (w_ij + w_ji) / Σ_k(w_ik + w_ki)
- Treats constraint as arising from mutual dependencies
- Matches NetworkX and igraph implementations
- **Use when:** Relationships are fundamentally bidirectional (collaboration, communication, friendship)

**`mode=:out`**: Out-edges only - ego's perspective
- Only outgoing edges i→j are considered
- Investment: p_ij = w_ij / Σ_k w_ik (where k ∈ outneighbors)
- Measures constraint from ego's unilateral investment choices
- **Use when:** Theory concerns ego's resource allocation decisions, strategic choices, or active relationship investments

**`mode=:in`**: In-edges only - others' perspectives on ego
- Only incoming edges j→i are considered
- Investment: p_ij = w_ji / Σ_k w_ki (where k ∈ inneighbors)
- Measures constraint from others' attention/investment in ego
- **Use when:** Theory concerns ego's prestige, popularity, or others' dependence on ego

See `docs/directed_graphs_theory.md` for detailed theoretical guidance on choosing modes.

## Implementation

- Automatically handles both weighted and unweighted graphs
- For unweighted graphs: uses binary edge presence
- For weighted graphs: uses edge weights (requires `weights` field)
- For directed graphs: uses `all_neighbors()` to include both in and out neighbors
- Uses memoization to avoid O(d³) redundant calculations (optimized to O(d²))
- Handles isolated nodes (returns 0.0)

## Arguments
- `g`: Graph object (Graph, DiGraph, weighted variants)
- `i`: Node index
- `mode`: Mode for directed graphs (`:both`, `:out`, or `:in`). Default: `:both`

## Returns
- `Float64`: Total constraint on node i (0 ≤ C_i ≤ n-1, where n is network size)
  - Returns 0.0 if node i has no neighbors

## Examples
```julia
using Graphs, NetworkConstraint

# Undirected graph
g = Graph(5)
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
c = constraint(g, 1)

# Directed graph with different modes
dg = DiGraph(4)
add_edge!(dg, 1, 2)  # 1→2
add_edge!(dg, 3, 1)  # 3→1
add_edge!(dg, 4, 1)  # 4→1

c_both = constraint(dg, 1; mode=:both)  # All 3 neighbors (in and out)
c_out = constraint(dg, 1; mode=:out)    # Only node 2 (outgoing)
c_in = constraint(dg, 1; mode=:in)      # Nodes 3 and 4 (incoming)

# Weighted directed graph
using SimpleWeightedGraphs
wdg = SimpleWeightedDiGraph(5)
add_edge!(wdg, 1, 2, 2.0)
add_edge!(wdg, 2, 1, 1.0)

# Use :out mode for ego's choice-based theories
c_out = constraint(wdg, 1; mode=:out)  # Ego's investment decisions
```

## References
- Burt, R.S. (1992). Structural Holes. Harvard University Press.
- Burt, R.S. (1993). The Social Structure of Competition.
- Everett & Borgatti (2020). Unpacking Burt's constraint measure. Social Networks, 62.

## See Also
- `dyadconstraint(g, i, j)`: Dyadic constraint between two nodes
- `investment(g, i, j)`: Proportional investment from i to j
- `docs/directed_graphs_theory.md`: Detailed theoretical discussion
"""
function constraint(g, i::Integer; mode::Symbol=:both)::Float64
    _validate_node(g, i)
    _validate_mode(mode)

    # Pre-compute all investments from i to its neighbors
    # Exclude self-loops (i→i) to match NetworkX/igraph behavior
    inv_cache = Dict{Int, Float64}()
    for j in _get_neighbors(g, i, mode)
        j != i && (inv_cache[j] = investment(g, i, j; mode=mode))
    end

    c = 0.0
    for j in _get_neighbors(g, i, mode)
        j != i && (c += _dyadconstraint(inv_cache, g, i, j, mode))
    end
    return c
end

# ============================================================================
# DYADIC CONSTRAINT - UNIFIED PUBLIC API
# ============================================================================

"""
        dyadconstraint(g, i, j; mode=:both)

## Description

Dyadic constraint c_ij for the tie between nodes i and j, defined in Burt (1993).

Formula: c_ij = (p_ij + Σ_q p_iq × p_qj)²

where p_ij is the investment from i to j.

For non-neighbors (no edge between i and j), returns 0.0.
Automatically handles both weighted and unweighted graphs.

## Mode Parameter for Directed Graphs

The `mode` parameter controls how investment is calculated (see `investment()` for details):

- **`mode=:both`** (default): Symmetrization - p_ij = (w_ij + w_ji) / Σ_k(w_ik + w_ki)
- **`mode=:out`**: Out-edges only - p_ij = w_ij / Σ_k w_ik
- **`mode=:in`**: In-edges only - p_ij = w_ji / Σ_k w_ki

See `docs/directed_graphs_theory.md` for theoretical implications and mode selection guidance.

## Arguments
- `g`: Graph object (Graph, DiGraph, weighted variants)
- `i`: Ego node (constrained by j)
- `j`: Alter node (constraining i)
- `mode`: Mode for directed graphs (`:both`, `:out`, or `:in`). Default: `:both`

## Returns
- `Float64`: Dyadic constraint (0 ≤ c_ij ≤ 1)
  - Returns 0.0 if i and j are not connected

## Examples
```julia
using Graphs, NetworkConstraint

# Undirected graph
g = Graph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 1, 3)

# How much does node 2 constrain node 1?
c_12 = dyadconstraint(g, 1, 2)

# Directed graph with different modes
dg = DiGraph(3)
add_edge!(dg, 1, 2)  # 1→2
add_edge!(dg, 2, 3)  # 2→3
add_edge!(dg, 3, 1)  # 3→1

dc_both = dyadconstraint(dg, 1, 2; mode=:both)  # Symmetrization
dc_out = dyadconstraint(dg, 1, 2; mode=:out)    # Out-edges only
dc_in = dyadconstraint(dg, 1, 2; mode=:in)      # In-edges only
```

## See Also
- `constraint(g, i)`: Total constraint on node i
- `investment(g, i, j)`: Direct investment component
- `docs/directed_graphs_theory.md`: Theoretical discussion
"""
function dyadconstraint(g, i::Integer, j::Integer; mode::Symbol=:both)::Float64
    _validate_nodes(g, i, j)
    _validate_mode(mode)
    return (investment(g, i, j; mode=mode) + investment_sum(g, i, j; mode=mode))^2
end

"""
        dyadconstraint(g, e; mode=:both)

## Description

Dyadic constraint for an edge object.

## Arguments
- `g`: Graph object (Graphs.jl)
- `e`: Edge object with `src(e)` and `dst(e)` methods
- `mode`: Mode for directed graphs (:both, :out, or :in)

## Returns
- `Float64`: Dyadic constraint value
"""
dyadconstraint(g, e::AbstractEdge; mode::Symbol=:both)::Float64 = dyadconstraint(g, src(e), dst(e); mode=mode)

# Memoized version with cache (for use inside constraint())
function _dyadconstraint(cache::Dict{Int, Float64}, g, i::Integer, j::Integer, mode::Symbol)::Float64
    return (cache[j] + _investment_sum(cache, g, i, j, mode))^2
end
