# helpers.jl

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

"""
    _is_weighted(g)

Checks if a graph has edge weights.
Returns true if the graph has a `weights` property (e.g., SimpleWeightedGraph).
"""
_is_weighted(g) = hasproperty(g, :weights)

"""
    _validate_mode(mode)

Validates that mode is one of :both, :out, or :in.
"""
function _validate_mode(mode::Symbol)
    mode ∈ (:both, :out, :in) || throw(ArgumentError("mode must be :both, :out, or :in, got :$mode"))
end

"""
    _get_neighbors(g, i, mode)

Get neighbors based on mode parameter.
- :both → all_neighbors (in and out)
- :out → outneighbors
- :in → inneighbors
"""
function _get_neighbors(g, i::Integer, mode::Symbol)
    if mode == :both
        return all_neighbors(g, i)
    elseif mode == :out
        return outneighbors(g, i)
    else  # mode == :in
        return inneighbors(g, i)
    end
end

"""
    _validate_node(g, i)

Validates that node `i` is valid in graph `g`.
"""
function _validate_node(g, i::Integer)
    i > 0 || throw(ArgumentError("Node index must be positive, got $i"))
    i ∈ vertices(g) || throw(ArgumentError("Node $i is not in the graph"))
end

"""
    _validate_nodes(g, i, j)

Validates that nodes `i` and `j` are valid in graph `g`.
"""
function _validate_nodes(g, i::Integer, j::Integer)
    i > 0 || throw(ArgumentError("Node index i must be positive, got $i"))
    j > 0 || throw(ArgumentError("Node index j must be positive, got $j"))
    i ∈ vertices(g) || throw(ArgumentError("Node $i is not in the graph"))
    j ∈ vertices(g) || throw(ArgumentError("Node $j is not in the graph"))
end
