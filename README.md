# NetworkConstraint.jl

A Julia package for calculating network constraint and structural holes measures in social networks, based on the work of Ronald Burt (1992).

## Overview

Network constraint measures the extent to which a node's connections are redundant, indicating fewer structural holes and less brokerage opportunity. This package provides efficient implementations for calculating:

- **Network constraint**: Overall constraint on a node
- **Dyadic constraint**: Constraint imposed by a specific tie
- **Investment**: Proportional investment in network ties

## Installation

This package has not been registered (yet):

```julia
using Pkg
Pkg.develop(path="/Users/emf/.julia/dev/NetworkConstraint")
```

## Usage

### Basic Example

```julia
using NetworkConstraint
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

## Implementation Details

- Automatically detects and handles both weighted and unweighted graphs
- Uses memoization to optimize constraint calculations from O(d�) to O(d�)
- Handles edge cases: isolated nodes, disconnected components
- All calculations follow Burt's original formulations

## Testing

Run the test suite:

```julia
using Pkg
Pkg.test("NetworkConstraint")
```

The test suite includes:
- Various graph types (star, cycle, path, complete graphs)
- Edge cases (isolated nodes, non-neighbors)
- Weighted and unweighted graphs
- Mathematical properties (symmetry, constraint decomposition)

## References

Burt, Ronald S. (1992). *Structural Holes: The Social Structure of Competition*. Cambridge, MA: Harvard University Press.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

Eric Martin Feltham <eric.feltham@aya.yale.edu>
