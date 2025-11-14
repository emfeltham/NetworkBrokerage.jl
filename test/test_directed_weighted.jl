using Test
using Graphs
using SimpleWeightedGraphs
using NetworkBrokerage

@testset "Directed Weighted Graph Tests" begin
    @testset "Weighted directed investment" begin
        g = SimpleWeightedDiGraph(3)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 1, 3, 1.0)

        inv_1_2 = NetworkBrokerage.investment(g, 1, 2)
        inv_1_3 = NetworkBrokerage.investment(g, 1, 3)

        @test inv_1_2 ≈ 2.0/3.0 atol=1e-10
        @test inv_1_3 ≈ 1.0/3.0 atol=1e-10
    end

    @testset "Asymmetric weights" begin
        g = SimpleWeightedDiGraph(2)
        add_edge!(g, 1, 2, 3.0)
        add_edge!(g, 2, 1, 1.0)

        inv_1_2 = NetworkBrokerage.investment(g, 1, 2)
        # Total weight = 3.0 + 1.0 = 4.0
        @test inv_1_2 ≈ 1.0 atol=1e-10
    end

    @testset "Weighted directed constraint" begin
        g = SimpleWeightedDiGraph(3)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 1, 3, 1.0)
        add_edge!(g, 2, 3, 1.5)

        c = constraint(g, 1)
        @test c isa Float64
        @test c >= 0.0
    end

    @testset "Weighted bidirectional edges" begin
        g = SimpleWeightedDiGraph(2)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 2, 1, 3.0)

        inv_1_2 = NetworkBrokerage.investment(g, 1, 2)
        # Investment: (2.0 + 3.0) / (2.0 + 3.0) = 1.0
        @test inv_1_2 ≈ 1.0 atol=1e-10

        c = constraint(g, 1)
        @test c ≈ 1.0 atol=1e-10
    end

    @testset "Weighted directed dyadic constraint" begin
        g = SimpleWeightedDiGraph(3)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 1, 3, 1.0)
        add_edge!(g, 2, 3, 1.0)

        dc_12 = dyadconstraint(g, 1, 2)
        dc_13 = dyadconstraint(g, 1, 3)

        @test dc_12 >= 0.0
        @test dc_13 >= 0.0
        @test dc_12 isa Float64
        @test dc_13 isa Float64
    end

    @testset "Weighted vs unweighted directed comparison" begin
        # Create unweighted directed graph
        g_unw = DiGraph(3)
        add_edge!(g_unw, 1, 2)
        add_edge!(g_unw, 1, 3)

        # Create equivalent weighted graph (all weights = 1.0)
        g_w = SimpleWeightedDiGraph(3)
        add_edge!(g_w, 1, 2, 1.0)
        add_edge!(g_w, 1, 3, 1.0)

        c_unw = constraint(g_unw, 1)
        c_w = constraint(g_w, 1)

        @test c_unw ≈ c_w atol=1e-10
    end

    @testset "Weighted directed star graph" begin
        g = SimpleWeightedDiGraph(5)
        # Center (node 1) points to all others with different weights
        add_edge!(g, 1, 2, 1.0)
        add_edge!(g, 1, 3, 2.0)
        add_edge!(g, 1, 4, 3.0)
        add_edge!(g, 1, 5, 4.0)

        c_center = constraint(g, 1)
        @test c_center isa Float64
        @test c_center >= 0.0

        # With symmetrization, spoke nodes have the center as an in-neighbor
        # So they are NOT isolated and have constraint = 1.0 (single neighbor = max constraint)
        c_spoke = constraint(g, 2)
        @test c_spoke ≈ 1.0 atol=1e-10
    end

    @testset "Weighted investment sum" begin
        g = SimpleWeightedDiGraph(3)
        add_edge!(g, 1, 2, 2.0)
        add_edge!(g, 1, 3, 1.0)
        add_edge!(g, 2, 3, 1.5)

        # Test investment sum function
        inv_sum = NetworkBrokerage.investment_sum(g, 1, 3)
        @test inv_sum isa Float64
        @test inv_sum >= 0.0
    end
end
