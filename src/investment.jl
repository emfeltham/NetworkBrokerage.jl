# investment.jl

# ============================================================================
# INVESTMENT - UNIFIED USING DISPATCH
# ============================================================================

"""
        investment(g, i, j; mode=:both)

## Description

Proportional investment from node i to node j using Burt's standard formulation.

For undirected graphs:
- Formula: p_ij = (e_ij + e_ji) / Σ_k (e_ik + e_ki)
- where e_ij = 1 if edge (i,j) exists, 0 otherwise

For directed graphs with `mode=:both` (default):
- Formula: p_ij = (e_ij + e_ji) / Σ_k (e_ik + e_ki)
- where k ranges over union(inneighbors(i), outneighbors(i))
- **Both directions contribute equally** (symmetrization)
- Handles asymmetric ties naturally (missing edges = 0)

For directed graphs with `mode=:out`:
- Formula: p_ij = e_ij / Σ_k e_ik
- where k ranges over outneighbors(i) only
- Only **outgoing edges** from i are considered
- Use when theory concerns ego's unilateral choices

For directed graphs with `mode=:in`:
- Formula: p_ij = e_ji / Σ_k e_ki
- where k ranges over inneighbors(i) only
- Only **incoming edges** to i are considered
- Use when theory concerns others' attention to ego

For weighted graphs:
- Same logic applies with edge weights w_ij instead of binary edges

## Mode Parameter

The `mode` parameter controls how directed edges are treated:

- **`:both`** (default): Symmetrization - both directions contribute equally
  - Appropriate when relationships are mutual (collaboration, communication)
  - Matches Burt's original formula and standard implementations
  - Use for fundamentally bidirectional relationships

- **`:out`**: Out-edges only - ego's outgoing ties
  - Appropriate when theory concerns ego's unilateral choices
  - Measures ego's investment decisions/resource allocation
  - Use for choice-based or strategic action theories

- **`:in`**: In-edges only - incoming ties to ego
  - Appropriate when theory concerns others' attention to ego
  - Measures others' investment in/attention to ego
  - Use for prestige, popularity, or influence theories

See `docs/directed_graphs_theory.md` for detailed theoretical guidance on choosing modes.

## Arguments
- `g`: Graph object (Graph, DiGraph, weighted variants)
- `i`: Source node
- `j`: Target node
- `mode`: Mode for directed graphs (`:both`, `:out`, or `:in`). Default: `:both`

## Returns
- `Float64`: Investment proportion (0 ≤ p_ij ≤ 1). Returns 0 if i has no neighbors.

## Examples
```julia
# Undirected graph
using Graphs
g = Graph(3)
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
p = investment(g, 1, 2)  # Investment from 1 to 2

# Directed graph with different modes
g = DiGraph(3)
add_edge!(g, 1, 2)  # 1→2
add_edge!(g, 3, 1)  # 3→1 (incoming to 1)

p_both = investment(g, 1, 2; mode=:both)  # Default: both directions
p_out = investment(g, 1, 2; mode=:out)    # Only outgoing 1→2
p_in = investment(g, 1, 2; mode=:in)      # Only incoming (0 for this edge)

# Weighted directed graph with modes
using SimpleWeightedGraphs
wg = SimpleWeightedDiGraph(3)
add_edge!(wg, 1, 2, 2.0)
add_edge!(wg, 1, 3, 1.0)

# With :out mode, measures ego's outgoing investment decisions
p_out = investment(wg, 1, 2; mode=:out)  # 2.0/(2.0+1.0) = 0.667
```

## References
- Burt, R.S. (1992). Structural Holes. Harvard University Press.
- Everett & Borgatti (2020). Unpacking Burt's constraint measure. Social Networks, 62.

## See Also
- `constraint(g, i)`: Total constraint on node i
- `dyadconstraint(g, i, j)`: Dyadic constraint from j on i
- `docs/directed_graphs_theory.md`: Detailed theoretical discussion
"""
function investment(g, i::Integer, j::Integer; mode::Symbol=:both)::Float64
    _validate_nodes(g, i, j)
    _validate_mode(mode)

    # Self-loops (i→i) are excluded from constraint calculations
    # Investment to self is always 0 (matches NetworkX/igraph)
    i == j && return 0.0

    if _is_weighted(g)
        # Weighted graph
        denom = _investment_denom_weighted(g, i, mode)
        denom == 0 && return 0.0
        w_ij = _get_weight(g, i, j)
        w_ji = _get_weight(g, j, i)

        # Numerator depends on mode
        numer = if mode == :both
            w_ij + w_ji  # Symmetrization
        elseif mode == :out
            w_ij  # Only outgoing
        else  # mode == :in
            w_ji  # Only incoming
        end

        return numer / denom
    else
        # Unweighted graph
        denom = _investment_denom_unweighted(g, i, mode)
        denom == 0 && return 0.0

        # Numerator depends on mode
        numer = if mode == :both
            has_edge(g, i, j) + has_edge(g, j, i)  # Symmetrization
        elseif mode == :out
            has_edge(g, i, j)  # Only outgoing
        else  # mode == :in
            has_edge(g, j, i)  # Only incoming
        end

        return numer / denom
    end
end

# ============================================================================
# INVESTMENT DENOMINATOR
# ============================================================================

# Unweighted denominator - supports mode parameter
function _investment_denom_unweighted(g, i::Integer, mode::Symbol)::Int
    c = 0
    # Get appropriate neighbors based on mode
    # Exclude self-loops (k != i) to match NetworkX/igraph behavior
    for k in _get_neighbors(g, i, mode)
        k == i && continue  # Skip self-loops
        if mode == :both
            # Symmetrization: count both directions
            c += has_edge(g, i, k) + has_edge(g, k, i)
        elseif mode == :out
            # Out-mode: count only outgoing edges
            c += has_edge(g, i, k)
        else  # mode == :in
            # In-mode: count only incoming edges
            c += has_edge(g, k, i)
        end
    end
    return c
end

# Weighted denominator - supports mode parameter
function _investment_denom_weighted(g, i::Integer, mode::Symbol)::Float64
    total = 0.0
    # Get appropriate neighbors based on mode
    # Exclude self-loops (k != i) to match NetworkX/igraph behavior
    for k in _get_neighbors(g, i, mode)
        k == i && continue  # Skip self-loops
        if mode == :both
            # Symmetrization: sum both directions
            total += _get_weight(g, i, k) + _get_weight(g, k, i)
        elseif mode == :out
            # Out-mode: sum only outgoing edges
            total += _get_weight(g, i, k)
        else  # mode == :in
            # In-mode: sum only incoming edges
            total += _get_weight(g, k, i)
        end
    end
    return total
end

# ============================================================================
# INVESTMENT SUM
# ============================================================================

"""
        investment_sum(g, i, j; mode=:both)

## Description

Computes the indirect investment from i to j through mutual neighbors.

Formula: Σ_q≠j p_iq × p_qj

This represents the sum of all indirect paths of length 2 from i to j,
weighted by the investment proportions.

## Arguments
- `g`: Graph object
- `i`: Source node
- `j`: Target node
- `mode`: Mode for directed graphs (:both, :out, or :in)

## Returns
- `Float64`: Sum of indirect investments from i to j
"""
function investment_sum(g, i::Integer, j::Integer; mode::Symbol=:both)::Float64
    _validate_nodes(g, i, j)
    _validate_mode(mode)
    c = 0.0
    # Use neighbors based on mode for ego i
    # Exclude self-loops: q should not be i or j
    for q in _get_neighbors(g, i, mode)
        (q != j && q != i) && (c += investment(g, i, q; mode=mode) * investment(g, q, j; mode=mode))
    end
    return c
end

# Memoized version (with cache, for use inside constraint())
function _investment_sum(cache::Dict{Int, Float64}, g, i::Integer, j::Integer, mode::Symbol)::Float64
    c = 0.0
    # Use neighbors based on mode for ego i
    # Exclude self-loops: q should not be i or j
    for q in _get_neighbors(g, i, mode)
        (q != j && q != i) && (c += cache[q] * investment(g, q, j; mode=mode))
    end
    return c
end
