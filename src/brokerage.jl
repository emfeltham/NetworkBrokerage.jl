"""
Gould-Fernandez brokerage calculation for network analysis.

Implements the five-role brokerage typology from Gould & Fernandez (1989).
"""

"""
    brokerage(g::AbstractGraph, groups::Union{AbstractVector, AbstractDict}; compute_modularity=false)

Calculate Gould-Fernandez brokerage roles for all nodes in a network.

A brokerage triad is a directed path i → ego → j where:
- i, ego, and j are three distinct nodes
- Edge i → ego exists and edge ego → j exists
- Direct edge i → j does NOT exist (ego mediates the path)

The five brokerage roles are classified by group membership:
- **Coordinator**: All three nodes in same group (g(ego) = g(i) = g(j))
- **Gatekeeper**: Ego and j in same group, i different (g(ego) = g(j) ≠ g(i))
- **Representative**: Ego and i in same group, j different (g(ego) = g(i) ≠ g(j))
- **Liaison**: i and j in same group, ego different (g(i) = g(j) ≠ g(ego))
- **Cosmopolitan**: All three nodes in different groups

# Arguments
- `g::AbstractGraph`: Network (directed or undirected)
- `groups::Union{AbstractVector, AbstractDict}`: Group assignment for each node
  - If Vector: `groups[i]` is the group of node i
  - If Dict: `groups[i]` is the group of node i (using vertex IDs as keys)
  - Groups can be any type (Int, String, Symbol, etc.)
- `compute_modularity::Bool`: If true, calculate Newman's modularity Q (default: false)

# Returns
`BrokerageResult` struct containing:
- Counts for each role type per node
- Total brokerage counts
- Group assignments
- Modularity value (if computed)

# Throws
- `ArgumentError` if group assignment doesn't match graph structure

# Examples
```julia
# Simple directed graph
g = DiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
groups = [1, 1, 2]

br = brokerage(g, groups)
println(br)  # Shows summary of brokerage roles

# Access individual counts
representative(br, 2)  # Node 2's representative count

# With modularity validation
br = brokerage(g, groups; compute_modularity=true)
if br.modularity > 0.3
    println("Strong group structure detected")
end

# Using named groups
departments = ["Sales", "Sales", "Engineering", "Engineering", "HR"]
br = brokerage(g, departments)
```

# Notes
- For undirected graphs, counts are automatically adjusted to avoid double-counting
- Self-loops are ignored in brokerage calculation
- For directed graphs, only the directed edge i→j is checked (not j→i)

# References
Gould, R. V., & Fernandez, R. M. (1989). Structures of mediation:
A formal approach to brokerage in transaction networks.
Sociological Methodology, 19, 89-126.
"""
function brokerage(
    g::AbstractGraph, groups::Union{AbstractVector, AbstractDict};
    compute_modularity::Bool=false
)
    # Validate inputs
    validate_groups(g, groups)

    # Convert Dict to Vector if needed
    if groups isa AbstractDict
        groups_vec = dict_to_vector(g, groups)
    else
        groups_vec = collect(groups)
    end

    n = nv(g)

    # Initialize result structure
    br = BrokerageResult(n, groups_vec)

    # Calculate brokerage for each node
    for ego in vertices(g)
        # Get ego's neighbors
        if is_directed(g)
            preds = inneighbors(g, ego)
            succs = outneighbors(g, ego)
        else
            preds = neighbors(g, ego)
            succs = neighbors(g, ego)
        end

        g_ego = get_group(groups_vec, ego)

        # Check all potential triads i → ego → j
        for i in preds
            for j in succs
                # Skip if i and j are the same (self-loop case)
                if i == j
                    continue
                end

                # Skip if direct edge i → j exists (not a brokerage relationship)
                # Note: For directed graphs, this checks only i→j, not j→i
                if has_edge(g, i, j)
                    continue
                end

                # Get groups and classify the brokerage role
                g_i = get_group(groups_vec, i)
                g_j = get_group(groups_vec, j)

                role = classify_brokerage_role(g_ego, g_i, g_j)

                # Increment the appropriate counter
                if role == :coordinator
                    br.coordinator[ego] += 1
                elseif role == :gatekeeper
                    br.gatekeeper[ego] += 1
                elseif role == :representative
                    br.representative[ego] += 1
                elseif role == :liaison
                    br.liaison[ego] += 1
                elseif role == :cosmopolitan
                    br.cosmopolitan[ego] += 1
                end
            end
        end
    end

    # For undirected graphs, divide by 2 to avoid double-counting
    # Each unordered triad {i, ego, j} is counted twice due to edge symmetry
    if !is_directed(g)
        for ego in vertices(g)
            br.coordinator[ego] ÷= 2
            br.gatekeeper[ego] ÷= 2
            br.representative[ego] ÷= 2
            br.liaison[ego] ÷= 2
            br.cosmopolitan[ego] ÷= 2
        end
    end

    # Calculate totals
    for ego in vertices(g)
        br.total[ego] = (br.coordinator[ego] + br.gatekeeper[ego] +
                        br.representative[ego] + br.liaison[ego] +
                        br.cosmopolitan[ego])
    end

    # Optional: Calculate modularity
    if compute_modularity
        # Convert groups to integers if needed
        if eltype(groups_vec) <: Integer
            int_groups = Vector{Int}(groups_vec)
        else
            int_groups = groups_to_integer(groups_vec)
        end

        # Calculate modularity using Graphs.jl built-in function
        Q = modularity(g, int_groups)

        # Create new result with modularity
        # Use typeof(br) to preserve the parametric type T
        T = eltype(br.groups)
        return BrokerageResult{T}(
            br.coordinator,
            br.gatekeeper,
            br.representative,
            br.liaison,
            br.cosmopolitan,
            br.total,
            br.groups,
            Q
        )
    end

    return br
end

"""
    brokerage(g::AbstractGraph, groups::Union{AbstractVector, AbstractDict}, ego::Int;
              compute_modularity=false) -> NamedTuple

Calculate brokerage roles for a single node (optimization for individual queries).

# Arguments
- `g::AbstractGraph`: Network
- `groups`: Group assignment
- `ego::Int`: Node to calculate brokerage for
- `compute_modularity::Bool`: If true, calculate modularity (default: false)

# Returns
NamedTuple with fields:
- `coordinator::Int`: Coordinator count
- `gatekeeper::Int`: Gatekeeper count
- `representative::Int`: Representative count
- `liaison::Int`: Liaison count
- `cosmopolitan::Int`: Cosmopolitan count
- `total::Int`: Sum of all roles
- `modularity::Union{Float64, Nothing}`: Modularity if computed

# Throws
- `ArgumentError` if group assignment invalid or ego not in graph

# Example
```julia
g = DiGraph(5)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 2, 4)
groups = [1, 1, 2, 2, 3]

result = brokerage(g, groups, 2)
println("Node 2 has \$(result.total) brokerage triads")
println("  Representative: \$(result.representative)")
```
"""
function brokerage(g::AbstractGraph, groups::Union{AbstractVector, AbstractDict}, ego::Int;
                   compute_modularity::Bool=false)
    # Validate inputs
    validate_groups(g, groups)

    if !(ego in vertices(g))
        throw(ArgumentError("Node $ego is not in the graph"))
    end

    # Convert Dict to Vector if needed
    if groups isa AbstractDict
        groups_vec = dict_to_vector(g, groups)
    else
        groups_vec = collect(groups)
    end

    # Initialize counters
    coord_count = 0
    gate_count = 0
    rep_count = 0
    liaison_count = 0
    cosmo_count = 0

    # Get ego's neighbors
    if is_directed(g)
        preds = inneighbors(g, ego)
        succs = outneighbors(g, ego)
    else
        preds = neighbors(g, ego)
        succs = neighbors(g, ego)
    end

    g_ego = get_group(groups_vec, ego)

    # Check all potential triads i → ego → j
    for i in preds
        for j in succs
            # Skip if i and j are the same (self-loop case)
            if i == j
                continue
            end

            # Skip if direct edge i → j exists (not a brokerage relationship)
            if has_edge(g, i, j)
                continue
            end

            # Get groups and classify the brokerage role
            g_i = get_group(groups_vec, i)
            g_j = get_group(groups_vec, j)

            role = classify_brokerage_role(g_ego, g_i, g_j)

            # Increment the appropriate counter
            if role == :coordinator
                coord_count += 1
            elseif role == :gatekeeper
                gate_count += 1
            elseif role == :representative
                rep_count += 1
            elseif role == :liaison
                liaison_count += 1
            elseif role == :cosmopolitan
                cosmo_count += 1
            end
        end
    end

    # For undirected graphs, divide by 2 to avoid double-counting
    if !is_directed(g)
        coord_count ÷= 2
        gate_count ÷= 2
        rep_count ÷= 2
        liaison_count ÷= 2
        cosmo_count ÷= 2
    end

    total_count = coord_count + gate_count + rep_count + liaison_count + cosmo_count

    # Optional: Calculate modularity for the entire graph
    mod_val = nothing
    if compute_modularity
        # Convert groups to integers if needed
        if eltype(groups_vec) <: Integer
            int_groups = Vector{Int}(groups_vec)
        else
            int_groups = groups_to_integer(groups_vec)
        end

        mod_val = modularity(g, int_groups)
    end

    return (
        coordinator = coord_count,
        gatekeeper = gate_count,
        representative = rep_count,
        liaison = liaison_count,
        cosmopolitan = cosmo_count,
        total = total_count,
        modularity = mod_val
    )
end
