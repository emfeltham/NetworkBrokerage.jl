# constraint.jl

# ============================================================================
# CONSTRAINT - UNIFIED PUBLIC API
# ============================================================================

"""
        constraint(g, i)

## Description

Network constraint for node i as defined in Burt (1992, 1993).

Formula: C_i = Σ_j c_ij = Σ_j (p_ij + Σ_q≠j p_iq × p_qj)²

where:
- p_ij is the proportional investment from i to j
- The sum is over all neighbors j of node i

Higher constraint indicates fewer structural holes and less brokerage opportunity.
Lower constraint indicates more structural holes and greater social capital.

## Implementation

- Automatically handles both weighted and unweighted graphs
- For unweighted graphs: uses binary edge presence
- For weighted graphs: uses edge weights (requires `weights` field)
- Uses memoization to avoid O(d³) redundant calculations (optimized to O(d²))
- Handles isolated nodes (returns 0.0)

## Arguments
- `g`: Graph object (Graphs.jl)
- `i`: Node index

## Returns
- `Float64`: Total constraint on node i (0 ≤ C_i ≤ degree(i))

## Example
```julia
using Graphs
g = cycle_graph(5)
c = constraint(g, 1)  # Constraint for node 1

# For weighted graphs:
using SimpleWeightedGraphs
wg = SimpleWeightedGraph(5)
add_edge!(wg, 1, 2, 2.0)
c = constraint(wg, 1)
```

## References
Burt, Ronald S. (1992). Structural Holes: The Social Structure of Competition.
Burt, Ronald S. (1993). The Social Structure of Competition.
"""
function constraint(g, i::Integer)::Float64
    _validate_node(g, i)

    # Pre-compute all investments from i to its neighbors
    inv_cache = Dict{Int, Float64}()
    for j in neighbors(g, i)
        inv_cache[j] = investment(g, i, j)
    end

    c = 0.0
    for j in neighbors(g, i)
        c += _dyadconstraint(inv_cache, g, i, j)
    end
    return c
end

export constraint

# ============================================================================
# DYADIC CONSTRAINT - UNIFIED PUBLIC API
# ============================================================================

"""
        dyadconstraint(g, i, j)

## Description

Dyadic constraint c_ij for the tie between nodes i and j, defined in Burt (1993).

Formula: c_ij = (p_ij + Σ_q p_iq × p_qj)²

where p_ij is the investment from i to j.

For non-neighbors (no edge between i and j), returns 0.0.
Automatically handles both weighted and unweighted graphs.

## Arguments
- `g`: Graph object (Graphs.jl)
- `i`: Source node
- `j`: Target node

## Returns
- `Float64`: Dyadic constraint value (0 ≤ c_ij ≤ 1)
"""
function dyadconstraint(g, i::Integer, j::Integer)::Float64
    _validate_nodes(g, i, j)
    return (investment(g, i, j) + investment_sum(g, i, j))^2
end

"""
        dyadconstraint(g, e)

## Description

Dyadic constraint for an edge object.

## Arguments
- `g`: Graph object (Graphs.jl)
- `e`: Edge object with `src(e)` and `dst(e)` methods

## Returns
- `Float64`: Dyadic constraint value
"""
dyadconstraint(g, e::AbstractEdge)::Float64 = dyadconstraint(g, src(e), dst(e))

export dyadconstraint

# Memoized version with cache (for use inside constraint())
function _dyadconstraint(cache::Dict{Int, Float64}, g, i::Integer, j::Integer)::Float64
    return (cache[j] + _investment_sum(cache, g, i, j))^2
end
