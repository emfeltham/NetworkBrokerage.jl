# weighted.jl

# ============================================================================
# WEIGHTED GRAPH HELPERS
# ============================================================================

"""
    _get_weight(g, i, j)

Helper to extract edge weight from weighted graph.
Returns 0.0 if edge doesn't exist.

Assumes graph has a `weights` field (e.g., SimpleWeightedGraph).
"""
function _get_weight(g, i::Integer, j::Integer)::Float64
    if has_edge(g, i, j)
        weight = g.weights[i, j]
        @assert weight >= 0 "Edge weight must be non-negative, got weight=$weight for edge ($i, $j)"
        return weight
    else
        return 0.0
    end
end
