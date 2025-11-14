"""
    BrokerageResult{T}

Result type for Gould-Fernandez brokerage analysis.

Parametric type that preserves the element type of group assignments for type stability.

# Type Parameter
- `T`: Element type of group assignments (e.g., String, Symbol, Int, CategoricalValue)

# Fields
- `coordinator::Vector{Int}`: Within-group brokerage counts (g(ego) = g(i) = g(j))
- `gatekeeper::Vector{Int}`: Gatekeeper counts (g(ego) = g(j) ≠ g(i))
- `representative::Vector{Int}`: Representative counts (g(ego) = g(i) ≠ g(j))
- `liaison::Vector{Int}`: Liaison counts (g(i) = g(j) ≠ g(ego))
- `cosmopolitan::Vector{Int}`: Cosmopolitan counts (all groups distinct)
- `total::Vector{Int}`: Total brokerage counts for each node
- `groups::Vector{T}`: Group assignments used in calculation (type-stable)
- `modularity::Union{Float64, Nothing}`: Newman's modularity Q (if computed)

# Examples
```julia
# String groups
br = brokerage(g, ["Sales", "Sales", "Eng"])
# typeof(br) == BrokerageResult{String}
# br.groups is Vector{String} (type-stable!)

# Symbol groups
br = brokerage(g, [:A, :B, :C])
# typeof(br) == BrokerageResult{Symbol}

# Integer groups
br = brokerage(g, [1, 1, 2])
# typeof(br) == BrokerageResult{Int64}

# CategoricalArray groups
using CategoricalArrays
br = brokerage(g, categorical(["Sales", "Eng"]))
# typeof(br) == BrokerageResult{CategoricalValue{String, UInt32}}
```

# References
Gould, R. V., & Fernandez, R. M. (1989). Structures of mediation:
A formal approach to brokerage in transaction networks.
Sociological Methodology, 19, 89-126.
"""
struct BrokerageResult{T}
    coordinator::Vector{Int}
    gatekeeper::Vector{Int}
    representative::Vector{Int}
    liaison::Vector{Int}
    cosmopolitan::Vector{Int}
    total::Vector{Int}
    groups::Vector{T}
    modularity::Union{Float64, Nothing}
end

"""
    BrokerageResult(n::Int, groups::AbstractVector{T}; modularity=nothing) where T

Construct a BrokerageResult with all counts initialized to zero.

The element type T of the groups vector is preserved for type stability.

# Arguments
- `n::Int`: Number of nodes in graph
- `groups::AbstractVector{T}`: Group assignments of element type T
- `modularity`: Optional modularity value (default: nothing)

# Returns
`BrokerageResult{T}` where T is the element type of groups

# Examples
```julia
# Infers T = String
br = BrokerageResult(5, ["A", "A", "B", "B", "C"])
typeof(br)  # BrokerageResult{String}

# Infers T = Int64
br = BrokerageResult(3, [1, 2, 3])
typeof(br)  # BrokerageResult{Int64}
```
"""
function BrokerageResult(n::Int, groups::AbstractVector{T}; modularity=nothing) where T
    BrokerageResult{T}(
        zeros(Int, n),
        zeros(Int, n),
        zeros(Int, n),
        zeros(Int, n),
        zeros(Int, n),
        zeros(Int, n),
        collect(groups),
        modularity
    )
end

# Accessor functions

"""
    coordinator(br::BrokerageResult, i::Int)

Get the coordinator count for node `i` (within-group brokerage).

Coordinator role: ego, i, and j all belong to the same group.
"""
coordinator(br::BrokerageResult, i::Int) = br.coordinator[i]

"""
    gatekeeper(br::BrokerageResult, i::Int)

Get the gatekeeper count for node `i` (incoming cross-group brokerage).

Gatekeeper role: ego and j are in the same group, i is in a different group.
"""
gatekeeper(br::BrokerageResult, i::Int) = br.gatekeeper[i]

"""
    representative(br::BrokerageResult, i::Int)

Get the representative count for node `i` (outgoing cross-group brokerage).

Representative role: ego and i are in the same group, j is in a different group.
"""
representative(br::BrokerageResult, i::Int) = br.representative[i]

"""
    liaison(br::BrokerageResult, i::Int)

Get the liaison count for node `i` (between-group brokerage).

Liaison role: i and j are in the same group, ego is in a different group.
"""
liaison(br::BrokerageResult, i::Int) = br.liaison[i]

"""
    cosmopolitan(br::BrokerageResult, i::Int)

Get the cosmopolitan count for node `i` (all groups distinct).

Cosmopolitan role: ego, i, and j all belong to different groups.
"""
cosmopolitan(br::BrokerageResult, i::Int) = br.cosmopolitan[i]

"""
    total_brokerage(br::BrokerageResult, i::Int)

Get the total brokerage count for node `i` (sum of all roles).
"""
total_brokerage(br::BrokerageResult, i::Int) = br.total[i]

# Display method

"""
    Base.show(io::IO, br::BrokerageResult)

Display a BrokerageResult with summary statistics.
"""
function Base.show(io::IO, br::BrokerageResult)
    n = length(br.total)
    total_coord = sum(br.coordinator)
    total_gate = sum(br.gatekeeper)
    total_rep = sum(br.representative)
    total_liaison = sum(br.liaison)
    total_cosmo = sum(br.cosmopolitan)
    total_all = sum(br.total)

    println(io, "BrokerageResult for $n nodes")
    println(io, "  Coordinator:     $total_coord")
    println(io, "  Gatekeeper:      $total_gate")
    println(io, "  Representative:  $total_rep")
    println(io, "  Liaison:         $total_liaison")
    println(io, "  Cosmopolitan:    $total_cosmo")
    println(io, "  Total:           $total_all")

    if br.modularity !== nothing
        Q = br.modularity
        # Interpret modularity strength
        interpretation = if Q > 0.3
            "strong group separation"
        elseif Q > 0.1
            "moderate group separation"
        else
            "weak or no group separation"
        end
        print(io, "  Modularity:      $(round(Q, digits=3)) ($interpretation)")
    end
end
