using Test
using Graphs
using NetworkConstraint

@testset "Directed Graph Tests" begin
    @testset "Simple directed graph investment" begin
        # Create simple directed graph: 1→2, 2→3, 3→1
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 1)

        # Node 1 has outgoing edge to 2, incoming from 3
        inv_1_2 = NetworkConstraint.investment(g, 1, 2)
        inv_1_3 = NetworkConstraint.investment(g, 1, 3)

        @test inv_1_2 isa Float64
        @test inv_1_3 isa Float64
        @test inv_1_2 + inv_1_3 ≈ 1.0 atol=1e-10
    end

    @testset "Asymmetric directed edges" begin
        # 1→2 exists, but 2→1 does not
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 1, 3)

        inv_1_2 = NetworkConstraint.investment(g, 1, 2)
        inv_1_3 = NetworkConstraint.investment(g, 1, 3)

        @test inv_1_2 ≈ 0.5 atol=1e-10
        @test inv_1_3 ≈ 0.5 atol=1e-10
    end

    @testset "Bidirectional edges in directed graph" begin
        # Both 1↔2 exists (both directions)
        g = DiGraph(2)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 1)

        inv_1_2 = NetworkConstraint.investment(g, 1, 2)
        @test inv_1_2 ≈ 1.0 atol=1e-10  # All investment goes to node 2
    end

    @testset "Directed graph constraint" begin
        # Star graph but directed
        g = DiGraph(5)
        for i in 2:5
            add_edge!(g, 1, i)  # Center points to all
        end

        c_center = constraint(g, 1)
        @test c_center isa Float64
        @test c_center >= 0.0
    end

    @testset "Mixed in/out neighbors" begin
        # Node 1: outgoing to 2, incoming from 3
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 3, 1)

        inv_1_2 = NetworkConstraint.investment(g, 1, 2)
        inv_1_3 = NetworkConstraint.investment(g, 1, 3)

        @test inv_1_2 + inv_1_3 ≈ 1.0 atol=1e-10
    end

    @testset "Directed dyadic constraint" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        dc_12 = dyadconstraint(g, 1, 2)
        dc_13 = dyadconstraint(g, 1, 3)

        @test dc_12 >= 0.0
        @test dc_13 >= 0.0
    end

    @testset "Directed graph regression vs undirected" begin
        # When directed graph is symmetric, should match undirected
        g_undir = Graph(4)
        add_edge!(g_undir, 1, 2)
        add_edge!(g_undir, 1, 3)
        add_edge!(g_undir, 2, 3)

        g_dir = DiGraph(4)
        add_edge!(g_dir, 1, 2)
        add_edge!(g_dir, 2, 1)
        add_edge!(g_dir, 1, 3)
        add_edge!(g_dir, 3, 1)
        add_edge!(g_dir, 2, 3)
        add_edge!(g_dir, 3, 2)

        c_undir = constraint(g_undir, 1)
        c_dir = constraint(g_dir, 1)

        @test c_undir ≈ c_dir atol=1e-10
    end

    @testset "Isolated node in directed graph" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        # Node 3 is isolated

        c_isolated = constraint(g, 3)
        @test c_isolated == 0.0
    end

    @testset "Empty directed graph" begin
        g = DiGraph(5)
        # No edges

        c = constraint(g, 1)
        @test c == 0.0
    end

    @testset "Directed cycle constraint values" begin
        # Create a directed cycle
        g = DiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 4)
        add_edge!(g, 4, 1)

        # All nodes should have same constraint due to symmetry
        c1 = constraint(g, 1)
        c2 = constraint(g, 2)
        c3 = constraint(g, 3)
        c4 = constraint(g, 4)

        @test c1 ≈ c2 atol=1e-10
        @test c2 ≈ c3 atol=1e-10
        @test c3 ≈ c4 atol=1e-10
    end
end
