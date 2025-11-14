"""
Helper functions for Gould-Fernandez brokerage calculation.

Internal functions used by the main brokerage implementation.
"""

"""
    classify_brokerage_role(g_ego, g_i, g_j) -> Symbol

Classify a brokerage triad (i → ego → j) into one of five roles based on group membership.

# Arguments
- `g_ego`: Group of ego (the broker)
- `g_i`: Group of i (incoming node)
- `g_j`: Group of j (outgoing node)

# Returns
- `:coordinator` if g_ego = g_i = g_j (within-group)
- `:gatekeeper` if g_ego = g_j ≠ g_i (incoming cross-group)
- `:representative` if g_ego = g_i ≠ g_j (outgoing cross-group)
- `:liaison` if g_i = g_j ≠ g_ego (between-group)
- `:cosmopolitan` if all groups are distinct

# Example
```julia
classify_brokerage_role("Sales", "Sales", "Eng")  # :representative
classify_brokerage_role("Sales", "Eng", "HR")     # :cosmopolitan
```
"""
function classify_brokerage_role(g_ego, g_i, g_j)
    if g_ego == g_i == g_j
        return :coordinator
    elseif g_ego == g_j && g_ego != g_i
        return :gatekeeper
    elseif g_ego == g_i && g_ego != g_j
        return :representative
    elseif g_i == g_j && g_i != g_ego
        return :liaison
    else
        return :cosmopolitan
    end
end

"""
    validate_groups(g::AbstractGraph, groups::Union{AbstractVector, AbstractDict})

Validate that group assignment is compatible with graph structure.

# Arguments
- `g::AbstractGraph`: The graph
- `groups`: Group assignment (Vector or Dict)

# Throws
- `ArgumentError` if validation fails with descriptive error message

# Checks
- For Vector: length must equal nv(g)
- For Dict: all vertices must be present as keys
- Type must be Vector or Dict
"""
function validate_groups(g::AbstractGraph, groups::Union{AbstractVector, AbstractDict})
    if groups isa AbstractVector
        if length(groups) != nv(g)
            throw(ArgumentError(
                "Group vector length ($(length(groups))) does not match number of vertices ($(nv(g)))"
            ))
        end
    elseif groups isa AbstractDict
        # Check that all vertices are present in the dict
        for v in vertices(g)
            if !haskey(groups, v)
                throw(ArgumentError(
                    "Vertex $v is missing from groups dictionary"
                ))
            end
        end
    else
        throw(ArgumentError(
            "Groups must be a Vector or Dict, got $(typeof(groups))"
        ))
    end
    return true
end

"""
    get_group(groups::Union{AbstractVector, AbstractDict}, i::Int)

Get the group assignment for node i.

# Arguments
- `groups`: Group assignment (Vector or Dict)
- `i::Int`: Node index

# Returns
Group value for node i (can be any type)
"""
function get_group(groups::AbstractVector, i::Int)
    return groups[i]
end

function get_group(groups::AbstractDict, i::Int)
    return groups[i]
end

"""
    dict_to_vector(g::AbstractGraph, groups::AbstractDict) -> Vector

Convert Dict-based group assignment to Vector format.

Uses the ordering from `vertices(g)` to create the vector, ensuring
correct alignment with graph structure regardless of vertex indexing.

# Arguments
- `g::AbstractGraph`: The graph
- `groups::AbstractDict`: Dict mapping vertex ID to group

# Returns
Vector where index i contains the group for vertex i (in vertices(g) order)

# Throws
- `KeyError` if any vertex is missing from dict (caught by validate_groups)

# Example
```julia
g = DiGraph(5)
groups_dict = Dict(1 => "A", 2 => "A", 3 => "B", 4 => "B", 5 => "C")
groups_vec = dict_to_vector(g, groups_dict)  # ["A", "A", "B", "B", "C"]
```

# Design Notes
- Preserves vertex ordering from graph
- Handles non-contiguous vertex indices correctly
- Works regardless of 0-indexed vs 1-indexed keys
"""
function dict_to_vector(g::AbstractGraph, groups::AbstractDict)
    return [groups[i] for i in vertices(g)]
end

"""
    groups_to_integer(groups::AbstractVector) -> Vector{Int}

Convert arbitrary group labels to integer indices for modularity calculation.

Uses Julia's `unique()` function which preserves first-occurrence order,
ensuring deterministic mapping from groups to integers.

# Arguments
- `groups::AbstractVector`: Group assignments (any type)

# Returns
Vector{Int} with same structure but integer group labels

# Example
```julia
groups = ["Sales", "Sales", "Eng", "Eng", "HR"]
int_groups = groups_to_integer(groups)  # [1, 1, 2, 2, 3]
```

# Determinism
- Julia's `unique()` preserves first-occurrence order (language guarantee)
- Same input will always produce same integer mapping
- "Sales" appears first → 1, "Eng" appears second → 2, etc.
"""
function groups_to_integer(groups::AbstractVector)
    # Get unique groups in first-occurrence order (deterministic)
    unique_groups = unique(groups)

    # Create mapping from group to integer
    group_map = Dict(g => i for (i, g) in enumerate(unique_groups))

    # Convert to integers
    return [group_map[g] for g in groups]
end
