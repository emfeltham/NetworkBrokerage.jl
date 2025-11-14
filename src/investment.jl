# investment.jl

# ============================================================================
# INVESTMENT - UNIFIED USING DISPATCH
# ============================================================================

"""
        investment(g, i, j)

## Description

Proportional investment from node i to node j.

For unweighted graphs:
- Formula: p_ij = (e_ij + e_ji) / Σ_k (e_ik + e_ki)
- where e_ij = 1 if edge (i,j) exists, 0 otherwise

For weighted graphs:
- Formula: p_ij = (w_ij + w_ji) / Σ_k (w_ik + w_ki)
- where w_ij is the weight of edge (i,j)

## Arguments
- `g`: Graph object (Graphs.jl)
- `i`: Source node
- `j`: Target node

## Returns
- `Float64`: Investment proportion (0 ≤ p_ij ≤ 1). Returns 0 if i has no neighbors.
"""
function investment(g, i::Integer, j::Integer)::Float64
    _validate_nodes(g, i, j)

    if _is_weighted(g)
        # Weighted graph
        denom = _investment_denom_weighted(g, i)
        denom == 0 && return 0.0
        w_ij = _get_weight(g, i, j)
        w_ji = _get_weight(g, j, i)
        return (w_ij + w_ji) / denom
    else
        # Unweighted graph
        denom = _investment_denom_unweighted(g, i)
        denom == 0 && return 0.0
        numer = has_edge(g, i, j) + has_edge(g, j, i)
        return numer / denom
    end
end

# ============================================================================
# INVESTMENT DENOMINATOR
# ============================================================================

# Unweighted denominator
function _investment_denom_unweighted(g, i::Integer)::Int
    c = 0
    for k in neighbors(g, i)
        c += has_edge(g, i, k) + has_edge(g, k, i)
    end
    return c
end

# Weighted denominator
function _investment_denom_weighted(g, i::Integer)::Float64
    total = 0.0
    for k in neighbors(g, i)
        total += _get_weight(g, i, k) + _get_weight(g, k, i)
    end
    return total
end

# ============================================================================
# INVESTMENT SUM
# ============================================================================

"""
        investment_sum(g, i, j)

## Description

Computes the indirect investment from i to j through mutual neighbors.

Formula: Σ_q≠j p_iq × p_qj

This represents the sum of all indirect paths of length 2 from i to j,
weighted by the investment proportions.

## Arguments
- `g`: Graph object
- `i`: Source node
- `j`: Target node

## Returns
- `Float64`: Sum of indirect investments from i to j
"""
function investment_sum(g, i::Integer, j::Integer)::Float64
    _validate_nodes(g, i, j)
    c = 0.0
    for q in neighbors(g, i)
        q != j && (c += investment(g, i, q) * investment(g, q, j))
    end
    return c
end

# Memoized version (with cache, for use inside constraint())
function _investment_sum(cache::Dict{Int, Float64}, g, i::Integer, j::Integer)::Float64
    c = 0.0
    for q in neighbors(g, i)
        q != j && (c += cache[q] * investment(g, q, j))
    end
    return c
end
