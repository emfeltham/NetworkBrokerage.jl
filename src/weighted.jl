# weighted.jl

# ============================================================================
# WEIGHTED GRAPH HELPERS
# ============================================================================

"""
    _get_weight(g, i, j)

Helper to extract edge weight from weighted graph.
Returns 0.0 if edge doesn't exist.

Assumes graph has a `weights` field (e.g., SimpleWeightedGraph).
For directed graphs with sparse weight matrices, uses SimpleWeightedGraphs.get_weight().
"""
function _get_weight(g, i::Integer, j::Integer)::Float64
    if has_edge(g, i, j)
        # Use SimpleWeightedGraphs.get_weight for proper sparse matrix handling
        weight = SimpleWeightedGraphs.get_weight(g, i, j)
        weight >= 0 || throw(ArgumentError("Edge weight must be non-negative, got weight=$weight for edge ($i, $j)"))
        return weight
    else
        return 0.0
    end
end
