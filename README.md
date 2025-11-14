# NetworkBrokerage.jl

A Julia package for calculating network constraint, structural holes, and brokerage measures in social networks, based on the work of Ronald Burt (1992) and Gould & Fernandez (1989).

## Overview

This package provides tools for analyzing social network positions and brokerage opportunities:

**Structural Holes & Constraint:**
- **Network constraint**: Overall constraint on a node (Burt 1992)
- **Dyadic constraint**: Constraint imposed by a specific tie
- **Investment**: Proportional investment in network ties

**Gould-Fernandez Brokerage:**
- **Five brokerage roles**: Coordinator, Gatekeeper, Representative, Liaison, Cosmopolitan
- **Group-based analysis**: Identify brokers between and within groups
- **Modularity integration**: Validate group structure before analysis

## Installation

This package has not been registered (yet):

```julia
using Pkg
Pkg.develop(path="/Users/emf/.julia/dev/NetworkBrokerage")
```

## Usage

### Basic Example

```julia
using NetworkBrokerage
using Graphs

# Create a simple graph
g = cycle_graph(5)

# Calculate constraint for a node
c = constraint(g, 1)

# Calculate dyadic constraint between two nodes
dc = dyadconstraint(g, 1, 2)
```

### Weighted Graphs

The package automatically handles weighted graphs:

```julia
using SimpleWeightedGraphs

# Create a weighted graph
wg = SimpleWeightedGraph(5)
add_edge!(wg, 1, 2, 2.0)
add_edge!(wg, 1, 3, 1.5)
add_edge!(wg, 2, 3, 1.0)

# Constraint calculations work the same way
c = constraint(wg, 1)
dc = dyadconstraint(wg, 1, 2)
```

### Directed Graphs

The package fully supports directed graphs with flexible mode parameter for different theoretical frameworks:

```julia
using Graphs

# Create a directed graph
g = DiGraph(5)
add_edge!(g, 1, 2)  # 1→2
add_edge!(g, 3, 1)  # 3→1
add_edge!(g, 4, 1)  # 4→1

# Default mode=:both uses symmetrization (standard approach)
c_both = constraint(g, 1)  # or explicitly: constraint(g, 1; mode=:both)

# mode=:out considers only outgoing edges (ego's choices)
c_out = constraint(g, 1; mode=:out)

# mode=:in considers only incoming edges (others' attention to ego)
c_in = constraint(g, 1; mode=:in)

# Also works with weighted directed graphs
using SimpleWeightedGraphs
wdg = SimpleWeightedDiGraph(5)
add_edge!(wdg, 1, 2, 2.0)
add_edge!(wdg, 2, 3, 1.5)

# Use mode parameter based on your theory
c = constraint(wdg, 1; mode=:out)  # Ego's investment decisions
```

#### Mode Parameter

The `mode` parameter controls how directed edges are treated:

**`mode=:both`** (default) - Symmetrization:
```
p_ij = (w_ij + w_ji) / Σ_k (w_ik + w_ki)
```
- Both directions contribute equally
- Standard Burt formula, matches NetworkX/igraph
- Use for mutual relationships (collaboration, communication)

**`mode=:out`** - Out-edges only:
```
p_ij = w_ij / Σ_k w_ik (k ∈ outneighbors)
```
- Only ego's outgoing ties
- Use for choice-based theories (resource allocation, strategic decisions)
- Measures ego's unilateral investment decisions

**`mode=:in`** - In-edges only:
```
p_ij = w_ji / Σ_k w_ki (k ∈ inneighbors)
```
- Only incoming ties to ego
- Use for prestige/popularity theories
- Measures others' attention to ego

**Implementation follows standard practice:**
- Matches NetworkX and igraph implementations
- Based on Burt's original formula with automatic symmetrization
- Both edge directions (i→j and j→i) contribute equally to constraint
- Treats relationships as fundamentally mutual dependencies

**Asymmetric ties:** When edges exist in only one direction, the formula naturally handles the asymmetry by setting the missing edge weight to 0.

#### Important Theoretical Considerations

**When this approach is appropriate:**
- Relationships are fundamentally bidirectional (collaboration, friendship, communication)
- Direction differences reflect measurement artifact rather than theoretical substance
- Networks are fully reciprocated or fully non-reciprocated
- Theory treats constraint as arising from mutual dependencies

**When you may need alternatives:**
- Your theory specifically concerns **ego's unilateral choices** (e.g., entrepreneurs allocating time/resources) → Consider future out-edge only mode
- Direction carries **fundamental theoretical meaning** (e.g., advice-seeking vs. advice-giving, citation flows) → May need separate in/out constraint measures
- **Resource flows are genuinely unidirectional** → Symmetrization may not capture your theoretical construct

**Critical:** The implementation treats constraint as arising from **mutual dependencies** rather than **unilateral investment choices**. If your theory uses language like "ego chooses" or "allocates resources," carefully consider whether symmetrization aligns with your theoretical model.

**For detailed theoretical discussion**, see [`docs/directed_graphs_theory.md`](docs/directed_graphs_theory.md), which covers:
- When symmetrization is/isn't appropriate
- Alternative measures for different research questions
- The theory-implementation mismatch identified by Borgatti (1997)
- Critical reporting requirements for publications

#### When Publishing Research

If you use this package with directed graphs in published research, your methods section should:

1. State that you used NetworkBrokerage.jl version X.Y
2. Explicitly mention that directed edges were symmetrized using (w_ij + w_ji)
3. Explain how this aligns with your theoretical model
4. Clarify that the measure captures mutual dependency rather than unilateral investment

See [`docs/directed_graphs_theory.md`](docs/directed_graphs_theory.md) for an example methods section you can adapt.

### Alternative Measures

If the standard symmetrization approach doesn't match your research question:

**Effective Size** (planned for v0.3.0): Simpler measure with clearer directional interpretation
- Counts non-redundant alters without symmetrization
- Can be calculated using only out-neighbors for directed graphs
- Borgatti (1997) found r=0.98 correlation with constraint

**Directional Modes**
```julia
constraint(g, i; mode=:both)  # Default (symmetrization)
constraint(g, i; mode=:out)   # Out-edges only
constraint(g, i; mode=:in)    # In-edges only
```

All three functions (`constraint`, `dyadconstraint`, `investment`) support the `mode` parameter.

**Manual Approaches**: Calculate constraint on edge-filtered subgraphs
- Extract out-edges only and calculate constraint (ego's choices)
- Extract in-edges only and calculate constraint (others' attention to ego)
- Compare which direction predicts your outcomes

For more details, see the [Alternative Measures section](docs/directed_graphs_theory.md#alternative-measures) in the theoretical documentation.

## Gould-Fernandez Brokerage

While network constraint measures structural holes (absence of connections), brokerage analysis identifies the specific roles nodes play when mediating connections between groups. This implementation follows the Gould-Fernandez (1989) five-role typology.

### What is Brokerage?

A **brokerage triad** is a directed path `i → ego → j` where:
- `i`, `ego`, and `j` are three distinct nodes
- Edges `i → ego` and `ego → j` exist
- Direct edge `i → j` does NOT exist (ego mediates the path)

The **brokerage role** depends on group membership:

| Role | Groups | Example |
|------|--------|---------|
| **Coordinator** | All same group | Manager mediating within a department |
| **Gatekeeper** | ego + j same, i different | Department head receiving info from outside |
| **Representative** | ego + i same, j different | Department head sending info outside |
| **Liaison** | i + j same, ego different | External consultant connecting department members |
| **Cosmopolitan** | All different groups | Broker spanning multiple unrelated groups |

### Basic Usage

```julia
using NetworkBrokerage
using Graphs

# Create a simple organizational network
g = DiGraph(5)
add_edge!(g, 1, 2)  # Person 1 → 2
add_edge!(g, 2, 3)  # Person 2 → 3
add_edge!(g, 2, 4)  # Person 2 → 4
add_edge!(g, 4, 5)  # Person 4 → 5

# Define department groups
departments = ["Sales", "Sales", "Engineering", "Engineering", "HR"]

# Calculate brokerage
br = brokerage(g, departments)

# View summary
println(br)
# BrokerageResult for 5 nodes
#   Coordinator:     0
#   Gatekeeper:      0
#   Representative:  2
#   Liaison:         0
#   Cosmopolitan:    0
#   Total:           2

# Access individual node's brokerage
total_brokerage(br, 2)    # Total brokerage for node 2
representative(br, 2)     # Representative role count
coordinator(br, 2)        # Coordinator role count
```

### Validating Group Structure with Modularity

Before analyzing brokerage, validate that your groups have structural basis:

```julia
# Calculate brokerage with modularity validation
br = brokerage(g, departments; compute_modularity=true)

if br.modularity > 0.3
    println("Strong group structure (Q = $(br.modularity))")
    println("Brokerage analysis is meaningful")

    # Identify key brokers
    for i in 1:nv(g)
        if total_brokerage(br, i) > 5
            println("Node $i is a key broker")
            println("  Coordinator: $(coordinator(br, i))")
            println("  Liaison: $(liaison(br, i))")
        end
    end
else
    println("Weak group structure (Q = $(br.modularity))")
    println("Consider alternative groupings")
end
```

**Modularity interpretation:**
- Q > 0.3: Strong group separation (brokerage analysis is meaningful)
- 0.1 < Q < 0.3: Moderate separation (interpret with caution)
- Q ≈ 0: No structural alignment (reconsider groups)

### Working with Different Group Types

Groups can be specified as integers, strings, symbols, or dictionaries:

```julia
# Integer groups
groups_int = [1, 1, 2, 2, 3]
br = brokerage(g, groups_int)

# Named groups (strings)
groups_str = ["Sales", "Sales", "Eng", "Eng", "HR"]
br = brokerage(g, groups_str)

# Symbol groups
groups_sym = [:A, :A, :B, :B, :C]
br = brokerage(g, groups_sym)

# Dictionary (useful for non-contiguous node IDs)
groups_dict = Dict(1 => "Sales", 2 => "Sales", 3 => "Eng", 4 => "Eng", 5 => "HR")
br = brokerage(g, groups_dict)
```

### Single-Node Query (Optimized)

For analyzing individual nodes without computing full network:

```julia
# Calculate brokerage for just node 2
result = brokerage(g, departments, 2)

println("Node 2 brokerage: $(result.total)")
println("  Representative: $(result.representative)")
println("  Coordinator: $(result.coordinator)")
```

### Interpreting Brokerage Roles

**High Coordinator Count:**
- Mediates within their own group
- Facilitates intra-group communication
- Example: Team leader coordinating within department

**High Gatekeeper Count:**
- Controls information flow into their group
- Filters external information for their group
- Example: Manager receiving client requests for team

**High Representative Count:**
- Projects their group's interests outward
- Represents group to external parties
- Example: Spokesperson or external liaison

**High Liaison Count:**
- Connects members of other groups
- Outside broker facilitating between groups
- Example: Consultant connecting client teams

**High Cosmopolitan Count:**
- Spans completely unrelated groups
- Bridges diverse, disconnected communities
- Example: Cross-functional innovation roles

### Directed vs. Undirected Graphs

The package handles both graph types correctly:

**Directed graphs:** Each directed path `i → ego → j` is counted once.
```julia
g = DiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
br = brokerage(g, [1, 1, 2])
# Node 2 has 1 representative triad
```

**Undirected graphs:** Counts are automatically halved to avoid double-counting.
```julia
g = Graph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
br = brokerage(g, [1, 1, 1])
# Node 2 has 1 coordinator triad (counted as 2, then halved)
```

### Brokerage vs. Constraint: When to Use Each

These measures capture different but related aspects of network position:

**Use Constraint when:**
- You want to measure structural holes (absence of connections)
- Focus is on individual autonomy and opportunities
- Question: "Who has non-redundant contacts?"
- Groups are not theoretically important
- Example: Entrepreneurial opportunity, innovation capacity

**Use Brokerage when:**
- You want to classify broker roles based on group membership
- Focus is on mediation between social groups
- Question: "Who connects which groups, and how?"
- Group boundaries are theoretically central
- Example: Organizational departments, social factions, communities

**Combined Analysis:**
```julia
# Low constraint + high brokerage = Powerful broker position
# High constraint + low brokerage = Embedded within single group
# Low constraint + low brokerage = Isolated or peripheral

for i in vertices(g)
    c = constraint(g, i)
    b = total_brokerage(br, i)

    if c < 0.3 && b > 10
        println("Node $i: Powerful broker (low constraint, high brokerage)")
    elseif c > 0.7 && b < 2
        println("Node $i: Embedded insider (high constraint, low brokerage)")
    end
end
```

### Implementation Notes

- **Self-loops:** Ignored in brokerage calculation
- **Directed edges:** For path `i → ego → j`, only checks if edge `i → j` exists (not `j → i`)
- **Complexity:** O(n · d²) where n = nodes, d = average degree
- **Performance:** Handles networks up to ~10,000 nodes efficiently

### Accessor Functions

All accessor functions available:
```julia
coordinator(br, i)      # Within-group brokerage
gatekeeper(br, i)       # Incoming cross-group
representative(br, i)   # Outgoing cross-group
liaison(br, i)          # Between-group (ego outside)
cosmopolitan(br, i)     # All groups different
total_brokerage(br, i)  # Sum of all roles
```

### References

**Brokerage:**
- Gould, R. V., & Fernandez, R. M. (1989). Structures of mediation: A formal approach to brokerage in transaction networks. *Sociological Methodology*, 19, 89-126.
- Stovel, K., & Shaw, L. (2012). Brokerage. *Annual Review of Sociology*, 38, 139-158.

**Theoretical foundation:**
- Simmel, G. (1950). The triad. In K. H. Wolff (Ed.), *The Sociology of Georg Simmel* (pp. 145-169). Free Press.

For detailed theoretical discussion, see [`docs/brokerage_theory.md`](docs/brokerage_theory.md).

## API Reference

### `constraint(g, i)`

Calculate the total network constraint on node `i`.

**Formula:** `C_i = �_j c_ij = �_j (p_ij + �_q`j p_iq � p_qj)�`

where:
- `p_ij` is the proportional investment from node i to node j
- The sum is over all neighbors j of node i

**Returns:** `Float64` - Total constraint (0 d C_i d degree(i))

**Interpretation:**
- Higher values indicate fewer structural holes and less brokerage opportunity
- Lower values indicate more structural holes and greater social capital

### `dyadconstraint(g, i, j)`

Calculate the dyadic constraint imposed by the tie between nodes `i` and `j`.

**Formula:** `c_ij = (p_ij + �_q p_iq � p_qj)�`

**Returns:** `Float64` - Dyadic constraint (0 d c_ij d 1)

**Note:** Can also accept an edge object: `dyadconstraint(g, edge)`

### `investment(g, i, j)`

Calculate the proportional investment from node `i` to node `j`.

**Formula (unweighted):** `p_ij = (e_ij + e_ji) / �_k (e_ik + e_ki)`

**Formula (weighted):** `p_ij = (w_ij + w_ji) / �_k (w_ik + w_ki)`

**Returns:** `Float64` - Investment proportion (0 d p_ij d 1)

### `investment_sum(g, i, j)`

Calculate the indirect investment from node `i` to node `j` through mutual neighbors.

**Formula:** `�_q`j p_iq � p_qj`

**Returns:** `Float64` - Sum of indirect investments

### `brokerage(g, groups; compute_modularity=false)`

Calculate Gould-Fernandez brokerage roles for all nodes.

**Arguments:**
- `g::AbstractGraph` - Network (directed or undirected)
- `groups::Union{AbstractVector, AbstractDict}` - Group assignment for each node
- `compute_modularity::Bool` - Optional keyword argument (default: `false`)

**Returns:** `BrokerageResult` - Struct containing brokerage counts for all nodes

**Example:**
```julia
br = brokerage(g, ["Sales", "Sales", "Eng"])
br = brokerage(g, [1, 1, 2]; compute_modularity=true)
```

### `brokerage(g, groups, ego; compute_modularity=false)`

Calculate brokerage for a single node (optimized).

**Arguments:**
- `g::AbstractGraph` - Network
- `groups::Union{AbstractVector, AbstractDict}` - Group assignment
- `ego::Int` - Node to analyze
- `compute_modularity::Bool` - Optional keyword argument (default: `false`)

**Returns:** `NamedTuple` with fields: `coordinator`, `gatekeeper`, `representative`, `liaison`, `cosmopolitan`, `total`, `modularity`

**Example:**
```julia
result = brokerage(g, groups, 2)
println("Total: $(result.total)")
```

### Brokerage Accessor Functions

- `coordinator(br, i)` - Within-group brokerage count for node i
- `gatekeeper(br, i)` - Gatekeeper role count for node i
- `representative(br, i)` - Representative role count for node i
- `liaison(br, i)` - Liaison role count for node i
- `cosmopolitan(br, i)` - Cosmopolitan role count for node i
- `total_brokerage(br, i)` - Total brokerage count for node i

## Implementation Details

- Automatically detects and handles both weighted and unweighted graphs
- Uses memoization to optimize constraint calculations from O(d�) to O(d�)
- Handles edge cases: isolated nodes, disconnected components
- All calculations follow Burt's original formulations

## Testing

Run the test suite:

```julia
using Pkg
Pkg.test("NetworkBrokerage")
```

The test suite includes:
- Various graph types (star, cycle, path, complete graphs)
- Edge cases (isolated nodes, non-neighbors)
- Weighted and unweighted graphs
- Mathematical properties (symmetry, constraint decomposition)
- Brokerage role classification and validation
- Integration tests with real networks (Karate Club)
- Modularity validation

## References

**Structural Holes & Constraint:**
- Burt, R.S. (1992). *Structural Holes: The Social Structure of Competition*. Cambridge, MA: Harvard University Press.
- Borgatti, S.P. (1997). Structural holes: Unpacking Burt's redundancy measures. *Connections*, 20(1), 35-38.
- Everett, M.G., & Borgatti, S.P. (2020). Unpacking Burt's constraint measure. *Social Networks*, 62, 50-57.

**Brokerage:**
- Gould, R.V., & Fernandez, R.M. (1989). Structures of mediation: A formal approach to brokerage in transaction networks. *Sociological Methodology*, 19, 89-126.
- Stovel, K., & Shaw, L. (2012). Brokerage. *Annual Review of Sociology*, 38, 139-158.
- Simmel, G. (1950). The triad. In K.H. Wolff (Ed.), *The Sociology of Georg Simmel* (pp. 145-169). Free Press.

**Network Analysis:**
- Borgatti, S.P., Everett, M.G., & Johnson, J.C. (2018). *Analyzing Social Networks* (2nd ed.). SAGE Publications.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

Eric Martin Feltham <eric.feltham@aya.yale.edu>
