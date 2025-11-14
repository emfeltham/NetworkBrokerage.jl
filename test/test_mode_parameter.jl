using Test
using Graphs
using SimpleWeightedGraphs
using NetworkConstraint

@testset "Mode Parameter Tests" begin
    @testset "Mode validation" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)

        # Valid modes should work
        @test constraint(g, 1; mode=:both) isa Float64
        @test constraint(g, 1; mode=:out) isa Float64
        @test constraint(g, 1; mode=:in) isa Float64

        # Invalid mode should error
        @test_throws ArgumentError constraint(g, 1; mode=:invalid)
    end

    @testset "Mode :both equals default" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 1)

        # Default should equal explicit :both
        @test constraint(g, 1) == constraint(g, 1; mode=:both)
        @test investment(g, 1, 2) == investment(g, 1, 2; mode=:both)
        @test dyadconstraint(g, 1, 2) == dyadconstraint(g, 1, 2; mode=:both)
    end

    @testset "Mode :out - outgoing edges only" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)  # 1→2
        add_edge!(g, 3, 1)  # 3→1 (incoming to 1)

        # With :out mode, node 1 has only one out-neighbor (node 2)
        inv_1_2_out = NetworkConstraint.investment(g, 1, 2; mode=:out)
        @test inv_1_2_out ≈ 1.0 atol=1e-10  # All outgoing investment to node 2

        # Node 3 not counted as neighbor in :out mode
        inv_1_3_out = NetworkConstraint.investment(g, 1, 3; mode=:out)
        @test inv_1_3_out == 0.0  # No outgoing edge to 3

        # Constraint based only on out-neighbors
        c_out = constraint(g, 1; mode=:out)
        @test c_out ≈ 1.0 atol=1e-10  # Single neighbor = max constraint
    end

    @testset "Mode :in - incoming edges only" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)  # 1→2 (outgoing from 1)
        add_edge!(g, 3, 1)  # 3→1 (incoming to 1)

        # With :in mode, node 1 has only one in-neighbor (node 3)
        inv_1_3_in = NetworkConstraint.investment(g, 1, 3; mode=:in)
        @test inv_1_3_in ≈ 1.0 atol=1e-10  # All incoming investment from node 3

        # Node 2 not counted in :in mode
        inv_1_2_in = NetworkConstraint.investment(g, 1, 2; mode=:in)
        @test inv_1_2_in == 0.0  # No incoming edge from 2

        # Constraint based only on in-neighbors
        c_in = constraint(g, 1; mode=:in)
        @test c_in ≈ 1.0 atol=1e-10  # Single neighbor = max constraint
    end

    @testset "Mode differences: :both vs :out vs :in" begin
        g = DiGraph(4)
        add_edge!(g, 1, 2)  # 1→2
        add_edge!(g, 3, 1)  # 3→1
        add_edge!(g, 4, 1)  # 4→1

        c_both = constraint(g, 1; mode=:both)
        c_out = constraint(g, 1; mode=:out)
        c_in = constraint(g, 1; mode=:in)

        # All three modes should give different results for asymmetric graph
        @test c_both != c_out
        @test c_both != c_in
        @test c_out != c_in

        # :both should consider all 3 neighbors
        # :out should consider only node 2
        # :in should consider nodes 3 and 4
    end

    @testset "Weighted directed graph with modes" begin
        g = SimpleWeightedDiGraph(3)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 1, 3, 1.0)

        # :both mode - symmetrization
        inv_both = NetworkConstraint.investment(g, 1, 2; mode=:both)
        @test inv_both ≈ 2.0/3.0 atol=1e-10

        # :out mode - only outgoing weights
        inv_out = NetworkConstraint.investment(g, 1, 2; mode=:out)
        @test inv_out ≈ 2.0/3.0 atol=1e-10  # 2.0/(2.0+1.0)

        # :in mode - no incoming edges
        inv_in = NetworkConstraint.investment(g, 1, 2; mode=:in)
        @test inv_in == 0.0  # No incoming edges to node 1
    end

    @testset "Reciprocal edges with different modes" begin
        g = DiGraph(2)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 1)

        # :both mode - fully reciprocated
        c_both = constraint(g, 1; mode=:both)
        @test c_both ≈ 1.0 atol=1e-10

        # :out mode - only 1→2
        c_out = constraint(g, 1; mode=:out)
        @test c_out ≈ 1.0 atol=1e-10

        # :in mode - only 2→1
        c_in = constraint(g, 1; mode=:in)
        @test c_in ≈ 1.0 atol=1e-10

        # All should be equal for symmetric case
        @test c_both ≈ c_out atol=1e-10
        @test c_both ≈ c_in atol=1e-10
    end

    @testset "Dyadic constraint with modes" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        dc_both = dyadconstraint(g, 1, 2; mode=:both)
        dc_out = dyadconstraint(g, 1, 2; mode=:out)
        dc_in = dyadconstraint(g, 1, 2; mode=:in)

        @test dc_both >= 0.0
        @test dc_out >= 0.0
        @test dc_in >= 0.0

        # Modes should give different results
        @test dc_both != dc_out
    end

    @testset "Star graph with different modes" begin
        g = DiGraph(5)
        # Center points to all spokes
        for i in 2:5
            add_edge!(g, 1, i)
        end

        # :both mode - spokes have center as in-neighbor
        c_spoke_both = constraint(g, 2; mode=:both)
        @test c_spoke_both ≈ 1.0 atol=1e-10

        # :out mode - spokes have no out-neighbors
        c_spoke_out = constraint(g, 2; mode=:out)
        @test c_spoke_out == 0.0  # No out-neighbors

        # :in mode - spokes have center as in-neighbor
        c_spoke_in = constraint(g, 2; mode=:in)
        @test c_spoke_in ≈ 1.0 atol=1e-10  # One in-neighbor

        # Center has low constraint in :out mode
        c_center_out = constraint(g, 1; mode=:out)
        @test c_center_out ≈ 0.25 atol=1e-10  # 4 disconnected out-neighbors
    end

    @testset "Cycle with modes" begin
        g = DiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 4)
        add_edge!(g, 4, 1)

        # All nodes should have same constraint in each mode due to symmetry
        c1_out = constraint(g, 1; mode=:out)
        c2_out = constraint(g, 2; mode=:out)
        c3_out = constraint(g, 3; mode=:out)
        c4_out = constraint(g, 4; mode=:out)

        @test c1_out ≈ c2_out atol=1e-10
        @test c2_out ≈ c3_out atol=1e-10
        @test c3_out ≈ c4_out atol=1e-10

        # Same for :in mode
        c1_in = constraint(g, 1; mode=:in)
        c2_in = constraint(g, 2; mode=:in)

        @test c1_in ≈ c2_in atol=1e-10

        # And :both mode
        c1_both = constraint(g, 1; mode=:both)
        c2_both = constraint(g, 2; mode=:both)

        @test c1_both ≈ c2_both atol=1e-10
    end

    @testset "Investment sum with modes" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 1, 3)
        add_edge!(g, 2, 3)

        # Test that investment_sum respects mode
        inv_sum_both = NetworkConstraint.investment_sum(g, 1, 3; mode=:both)
        inv_sum_out = NetworkConstraint.investment_sum(g, 1, 3; mode=:out)

        @test inv_sum_both >= 0.0
        @test inv_sum_out >= 0.0
    end

    @testset "Empty neighbor sets with modes" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        # Node 3 is isolated

        # All modes should return 0 for isolated node
        @test constraint(g, 3; mode=:both) == 0.0
        @test constraint(g, 3; mode=:out) == 0.0
        @test constraint(g, 3; mode=:in) == 0.0
    end
end
