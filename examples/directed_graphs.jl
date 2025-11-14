# Examples: Directed Graph Support in NetworkConstraint.jl
#
# This file demonstrates how to use NetworkConstraint.jl with directed graphs
# and illustrates the symmetrization approach used in the implementation.

using NetworkConstraint
using Graphs
using SimpleWeightedGraphs

println("=" ^ 70)
println("NetworkConstraint.jl - Directed Graph Examples")
println("=" ^ 70)
println()

# ==============================================================================
# Example 1: Simple Directed Cycle
# ==============================================================================

println("Example 1: Directed Cycle (1→2→3→4→1)")
println("-" ^ 70)

g = DiGraph(4)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 3, 4)
add_edge!(g, 4, 1)

for i in 1:4
    c = constraint(g, i)
    println("  Constraint for node $i: $(round(c, digits=4))")
end

println()
println("  Note: All nodes have same constraint due to structural symmetry")
println("  of the cycle, even though edges are directed.")
println()

# ==============================================================================
# Example 2: Directed Star (Hub and Spokes)
# ==============================================================================

println("Example 2: Directed Star (center → spokes)")
println("-" ^ 70)

g = DiGraph(5)
for i in 2:5
    add_edge!(g, 1, i)  # Center (node 1) points to all spokes
end

c_center = constraint(g, 1)
c_spoke = constraint(g, 2)

println("  Center (node 1) constraint: $(round(c_center, digits=4))")
println("  Spoke (node 2) constraint: $(round(c_spoke, digits=4))")
println()
println("  Note: With symmetrization, spokes have center as in-neighbor.")
println("  Spoke constraint = 1.0 because they have only one neighbor.")
println("  Center has low constraint due to multiple disconnected contacts.")
println()

# ==============================================================================
# Example 3: Asymmetric Relationships
# ==============================================================================

println("Example 3: Asymmetric Relationships")
println("-" ^ 70)

g = DiGraph(3)
add_edge!(g, 1, 2)  # 1→2 only (non-reciprocal)
add_edge!(g, 1, 3)  # 1→3 only
add_edge!(g, 3, 1)  # 3→1 (making 1↔3 reciprocal)

println("  Network structure:")
println("    1→2 (non-reciprocal)")
println("    1↔3 (reciprocal)")
println()

inv_1_2 = NetworkConstraint.investment(g, 1, 2)
inv_1_3 = NetworkConstraint.investment(g, 1, 3)

println("  Investment from node 1:")
println("    to node 2: $(round(inv_1_2, digits=4))")
println("    to node 3: $(round(inv_1_3, digits=4))")
println("    sum: $(round(inv_1_2 + inv_1_3, digits=4))")
println()

c1 = constraint(g, 1)
println("  Constraint for node 1: $(round(c1, digits=4))")
println()
println("  Note: Both 1→2 and 1↔3 contribute to node 1's constraint.")
println("  The symmetrization treats both relationships as mutual.")
println()

# ==============================================================================
# Example 4: Comparison with Undirected Equivalent
# ==============================================================================

println("Example 4: Symmetric Directed vs Undirected")
println("-" ^ 70)

# Create undirected graph
g_undir = Graph(4)
add_edge!(g_undir, 1, 2)
add_edge!(g_undir, 1, 3)
add_edge!(g_undir, 2, 3)

# Create equivalent symmetric directed graph (all edges bidirectional)
g_dir = DiGraph(4)
add_edge!(g_dir, 1, 2)
add_edge!(g_dir, 2, 1)
add_edge!(g_dir, 1, 3)
add_edge!(g_dir, 3, 1)
add_edge!(g_dir, 2, 3)
add_edge!(g_dir, 3, 2)

c_undir = constraint(g_undir, 1)
c_dir = constraint(g_dir, 1)

println("  Undirected graph constraint: $(round(c_undir, digits=4))")
println("  Symmetric directed constraint: $(round(c_dir, digits=4))")
println("  Difference: $(round(abs(c_undir - c_dir), digits=10))")
println()
println("  Note: When directed graph is fully reciprocated, results match")
println("  undirected graph exactly (as proven by Everett & Borgatti 2020).")
println()

# ==============================================================================
# Example 5: Weighted Directed Graph
# ==============================================================================

println("Example 5: Weighted Directed Graph")
println("-" ^ 70)

g = SimpleWeightedDiGraph(3)
add_edge!(g, 1, 2, 2.0)  # Strong tie 1→2
add_edge!(g, 1, 3, 1.0)  # Weak tie 1→3
add_edge!(g, 2, 3, 1.5)  # Medium tie 2→3

inv_1_2 = NetworkConstraint.investment(g, 1, 2)
inv_1_3 = NetworkConstraint.investment(g, 1, 3)

println("  Edge weights:")
println("    1→2: 2.0 (strong)")
println("    1→3: 1.0 (weak)")
println("    2→3: 1.5 (medium)")
println()
println("  Investment from node 1:")
println("    to node 2: $(round(inv_1_2, digits=4)) (stronger tie gets more investment)")
println("    to node 3: $(round(inv_1_3, digits=4))")
println()

c1 = constraint(g, 1)
c2 = constraint(g, 2)
println("  Constraint:")
println("    Node 1: $(round(c1, digits=4))")
println("    Node 2: $(round(c2, digits=4))")
println()

# ==============================================================================
# Example 6: Weighted Asymmetric Ties
# ==============================================================================

println("Example 6: Weighted Asymmetric Ties")
println("-" ^ 70)

g = SimpleWeightedDiGraph(2)
add_edge!(g, 1, 2, 3.0)  # Strong 1→2
add_edge!(g, 2, 1, 1.0)  # Weak 2→1

println("  Edge weights:")
println("    1→2: 3.0 (strong outgoing)")
println("    2→1: 1.0 (weak incoming)")
println()

inv_1_2 = NetworkConstraint.investment(g, 1, 2)
println("  Investment from 1 to 2: $(round(inv_1_2, digits=4))")
println("  (combines both directions: (3.0 + 1.0) / (3.0 + 1.0) = 1.0)")
println()

c1 = constraint(g, 1)
c2 = constraint(g, 2)
println("  Constraint:")
println("    Node 1: $(round(c1, digits=4))")
println("    Node 2: $(round(c2, digits=4))")
println()
println("  Note: Asymmetric weights are summed in symmetrization.")
println("  Both nodes have single neighbor, so constraint = 1.0.")
println()

# ==============================================================================
# Example 7: Dyadic Constraint in Directed Graphs
# ==============================================================================

println("Example 7: Dyadic Constraint")
println("-" ^ 70)

g = DiGraph(3)
add_edge!(g, 1, 2)  # Direct 1→2
add_edge!(g, 2, 3)  # Indirect path through 2
add_edge!(g, 1, 3)  # Direct 1→3

dc_12 = dyadconstraint(g, 1, 2)
dc_13 = dyadconstraint(g, 1, 3)

println("  Network structure:")
println("    1→2→3 (indirect path)")
println("    1→3 (direct connection)")
println()
println("  Dyadic constraint on node 1:")
println("    from node 2: $(round(dc_12, digits=4))")
println("    from node 3: $(round(dc_13, digits=4))")
println()

total = constraint(g, 1)
println("  Total constraint: $(round(total, digits=4))")
println("  (sum of dyadic constraints from all neighbors)")
println()

# ==============================================================================
# Example 8: Comparing Different Graph Configurations
# ==============================================================================

println("Example 8: Graph Configuration Comparison")
println("-" ^ 70)

# Configuration A: One-way connections
g_oneway = DiGraph(4)
add_edge!(g_oneway, 1, 2)
add_edge!(g_oneway, 1, 3)
add_edge!(g_oneway, 1, 4)

# Configuration B: Two-way connections
g_twoway = DiGraph(4)
add_edge!(g_twoway, 1, 2)
add_edge!(g_twoway, 2, 1)
add_edge!(g_twoway, 1, 3)
add_edge!(g_twoway, 3, 1)
add_edge!(g_twoway, 1, 4)
add_edge!(g_twoway, 4, 1)

# Configuration C: Mixed
g_mixed = DiGraph(4)
add_edge!(g_mixed, 1, 2)  # One-way
add_edge!(g_mixed, 1, 3)  # One-way
add_edge!(g_mixed, 3, 1)  # Making 1↔3
add_edge!(g_mixed, 1, 4)
add_edge!(g_mixed, 4, 1)  # Making 1↔4

c_oneway = constraint(g_oneway, 1)
c_twoway = constraint(g_twoway, 1)
c_mixed = constraint(g_mixed, 1)

println("  Configuration A (all one-way 1→X):")
println("    Constraint: $(round(c_oneway, digits=4))")
println()
println("  Configuration B (all two-way 1↔X):")
println("    Constraint: $(round(c_twoway, digits=4))")
println()
println("  Configuration C (mixed one-way and two-way):")
println("    Constraint: $(round(c_mixed, digits=4))")
println()
println("  Note: Configuration A and C have same constraint because")
println("  symmetrization counts both 1→X and X→1 equally.")
println()

# ==============================================================================
# Summary and Recommendations
# ==============================================================================

println("=" ^ 70)
println("Summary: Understanding Symmetrization")
println("=" ^ 70)
println()
println("Key Points:")
println("  1. Both i→j and j→i contribute equally to constraint")
println("  2. Asymmetric ties are handled by treating missing edges as weight 0")
println("  3. Fully reciprocated directed graphs = undirected graphs")
println("  4. The measure treats relationships as mutual dependencies")
println()
println("When This Approach Works:")
println("  ✓ Collaboration networks (mutual engagement)")
println("  ✓ Communication networks (any contact matters)")
println("  ✓ Friendship networks (typically reciprocal)")
println("  ✓ Direction reflects measurement artifact")
println()
println("When You May Need Alternatives:")
println("  ⚠ Ego's unilateral choices (resource allocation)")
println("  ⚠ Directional theories (advice-seeking vs giving)")
println("  ⚠ Unidirectional resource flows")
println()
println("For detailed discussion, see: docs/directed_graphs_theory.md")
println("=" ^ 70)
