using Test
using Graphs
using SimpleWeightedGraphs
using NetworkBrokerage

@testset "Self-Loop Handling Tests" begin
    @testset "Self-loops excluded from constraint" begin
        # Graph with self-loop
        g_with = DiGraph(3)
        add_edge!(g_with, 1, 1)  # Self-loop
        add_edge!(g_with, 1, 2)
        add_edge!(g_with, 2, 3)

        # Same graph without self-loop
        g_without = DiGraph(3)
        add_edge!(g_without, 1, 2)
        add_edge!(g_without, 2, 3)

        # Constraint should be identical (self-loop excluded)
        c_with = constraint(g_with, 1)
        c_without = constraint(g_without, 1)

        @test c_with ≈ c_without atol=1e-10
    end

    @testset "Node with only self-loop is isolated" begin
        g = DiGraph(3)
        add_edge!(g, 1, 1)  # Only self-loop on node 1
        add_edge!(g, 2, 3)  # Other nodes connected

        # Node with only self-loop should have constraint = 0 (isolated)
        c = constraint(g, 1)
        @test c == 0.0
    end

    @testset "Self-loops in undirected graphs" begin
        g_with = Graph(3)
        add_edge!(g_with, 1, 1)  # Self-loop
        add_edge!(g_with, 1, 2)
        add_edge!(g_with, 2, 3)

        g_without = Graph(3)
        add_edge!(g_without, 1, 2)
        add_edge!(g_without, 2, 3)

        c_with = constraint(g_with, 1)
        c_without = constraint(g_without, 1)

        @test c_with ≈ c_without atol=1e-10
    end

    @testset "Self-loops in weighted directed graphs" begin
        g_with = SimpleWeightedDiGraph(3)
        add_edge!(g_with, 1, 1, 5.0)  # Heavy self-loop (should be ignored)
        add_edge!(g_with, 1, 2, 2.0)
        add_edge!(g_with, 1, 3, 1.0)

        g_without = SimpleWeightedDiGraph(3)
        add_edge!(g_without, 1, 2, 2.0)
        add_edge!(g_without, 1, 3, 1.0)

        c_with = constraint(g_with, 1)
        c_without = constraint(g_without, 1)

        @test c_with ≈ c_without atol=1e-10
    end

    @testset "Self-loops with different modes" begin
        g = DiGraph(4)
        add_edge!(g, 1, 1)  # Self-loop
        add_edge!(g, 1, 2)
        add_edge!(g, 3, 1)
        add_edge!(g, 4, 1)

        # All modes should exclude self-loop
        c_both = constraint(g, 1; mode=:both)
        c_out = constraint(g, 1; mode=:out)
        c_in = constraint(g, 1; mode=:in)

        @test c_both isa Float64
        @test c_out isa Float64
        @test c_in isa Float64

        # Values should be based on actual neighbors, not self-loop
        @test c_out ≈ 1.0 atol=1e-10  # One out-neighbor (node 2)
        @test c_in ≈ 0.5 atol=1e-10   # Two in-neighbors (nodes 3, 4)
    end

    @testset "Investment excludes self-loops" begin
        g = DiGraph(3)
        add_edge!(g, 1, 1)  # Self-loop
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        # Investment to self should be 0
        inv_self = NetworkBrokerage.investment(g, 1, 1)
        @test inv_self == 0.0

        # Investment to others should not be affected by self-loop
        inv_2 = NetworkBrokerage.investment(g, 1, 2)
        @test inv_2 ≈ 1.0 atol=1e-10  # All investment to node 2
    end

    @testset "Complex graph with multiple self-loops" begin
        g_with = DiGraph(5)
        add_edge!(g_with, 1, 1)  # Self-loops
        add_edge!(g_with, 2, 2)
        add_edge!(g_with, 3, 3)
        add_edge!(g_with, 1, 2)  # Real edges
        add_edge!(g_with, 1, 3)
        add_edge!(g_with, 2, 3)

        g_without = DiGraph(5)
        add_edge!(g_without, 1, 2)
        add_edge!(g_without, 1, 3)
        add_edge!(g_without, 2, 3)

        # All nodes' constraints should be unaffected by self-loops
        for i in 1:3
            c_with = constraint(g_with, i)
            c_without = constraint(g_without, i)
            @test c_with ≈ c_without atol=1e-10
        end
    end
end
