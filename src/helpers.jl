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
    _validate_node(g, i)

Validates that node `i` is valid in graph `g`.
"""
function _validate_node(g, i::Integer)
    @assert i > 0 "Node index must be positive, got $i"
    @assert i ∈ vertices(g) "Node $i is not in the graph"
    @assert nv(g) > 0 "Graph is empty"
end

"""
    _validate_nodes(g, i, j)

Validates that nodes `i` and `j` are valid in graph `g`.
"""
function _validate_nodes(g, i::Integer, j::Integer)
    @assert i > 0 "Node index i must be positive, got $i"
    @assert j > 0 "Node index j must be positive, got $j"
    @assert i ∈ vertices(g) "Node $i is not in the graph"
    @assert j ∈ vertices(g) "Node $j is not in the graph"
    @assert nv(g) > 0 "Graph is empty"
end
