using Test
using Graphs
using SimpleWeightedGraphs
using NetworkBrokerage

@testset "Negative Weight Validation Tests" begin
    @testset "Negative weights cause ArgumentError when directly accessed" begin
        g = SimpleWeightedGraph(3)
        add_edge!(g, 1, 2, 2.0)   # Valid positive weight
        add_edge!(g, 2, 3, -1.0)  # Invalid negative weight

        # Should throw ArgumentError when node 2 calculates constraint
        # because it directly uses edge (2,3) with negative weight
        @test_throws ArgumentError constraint(g, 2)

        # Node 3 also uses edge (2,3)
        @test_throws ArgumentError constraint(g, 3)
    end

    @testset "Negative weights cause ArgumentError in investment()" begin
        g = SimpleWeightedGraph(3)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 2, 3, -1.0)  # Negative weight

        # Should throw when calculating investment involving negative weight
        @test_throws ArgumentError NetworkBrokerage.investment(g, 2, 3)
        @test_throws ArgumentError NetworkBrokerage.investment(g, 3, 2)
    end

    @testset "Negative weights cause ArgumentError in dyadconstraint()" begin
        g = SimpleWeightedGraph(3)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 2, 3, -1.0)

        # Should throw when calculating dyadic constraint with negative weight
        @test_throws ArgumentError dyadconstraint(g, 2, 3)
    end

    @testset "Negative weights in directed graphs" begin
        g = SimpleWeightedDiGraph(3)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 2, 3, -1.5)  # Negative weight

        # Should throw ArgumentError for nodes that use this edge
        @test_throws ArgumentError constraint(g, 2)
        @test_throws ArgumentError constraint(g, 3)
        @test_throws ArgumentError NetworkBrokerage.investment(g, 2, 3)
        @test_throws ArgumentError dyadconstraint(g, 2, 3)
    end

    @testset "Negative weights with different modes" begin
        g = SimpleWeightedDiGraph(4)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 1, 3, -1.0)  # Negative weight on out-edge
        add_edge!(g, 4, 1, 1.0)

        # Should throw with modes that use the negative weight edge
        @test_throws ArgumentError constraint(g, 1; mode=:both)  # Uses out-edge (1,3)
        @test_throws ArgumentError constraint(g, 1; mode=:out)   # Uses out-edge (1,3)

        # mode=:in only looks at incoming edges (4→1), which are valid
        # So this should NOT throw
        @test constraint(g, 1; mode=:in) isa Float64
    end

    @testset "Negative incoming edge with modes" begin
        g = SimpleWeightedDiGraph(3)
        add_edge!(g, 1, 2, -1.0)  # Negative weight on incoming edge to 2
        add_edge!(g, 2, 3, 2.0)

        # mode=:in uses incoming edges, so should throw for node 2
        @test_throws ArgumentError constraint(g, 2; mode=:in)

        # mode=:out only uses outgoing edges (2→3), which is valid
        @test constraint(g, 2; mode=:out) isa Float64
    end

    @testset "Zero weights are valid" begin
        g = SimpleWeightedGraph(3)
        add_edge!(g, 1, 2, 0.0)  # Zero weight is valid
        add_edge!(g, 1, 3, 1.0)

        # Should NOT throw (though zero weight edges have no effect)
        @test constraint(g, 1) isa Float64
        @test NetworkBrokerage.investment(g, 1, 2) isa Float64
    end

    @testset "Positive weights remain valid" begin
        g = SimpleWeightedGraph(3)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 2, 3, 1.5)
        add_edge!(g, 1, 3, 1.0)

        # Should all work fine
        @test constraint(g, 1) isa Float64
        @test constraint(g, 2) isa Float64
        @test constraint(g, 3) isa Float64
        @test NetworkBrokerage.investment(g, 1, 2) isa Float64
        @test dyadconstraint(g, 1, 2) isa Float64
    end

    @testset "Very small positive weights are valid" begin
        g = SimpleWeightedGraph(3)
        add_edge!(g, 1, 2, 1e-10)  # Very small but positive
        add_edge!(g, 1, 3, 1.0)

        # Should work fine
        @test constraint(g, 1) isa Float64
        @test NetworkBrokerage.investment(g, 1, 2) isa Float64
    end

    @testset "Error message contains useful information" begin
        g = SimpleWeightedDiGraph(3)
        add_edge!(g, 1, 2, -5.0)

        # Check that error message is informative
        try
            constraint(g, 1)
            @test false  # Should not reach here
        catch e
            @test e isa ArgumentError
            @test occursin("non-negative", e.msg)
            @test occursin("weight", e.msg)
        end
    end
end
