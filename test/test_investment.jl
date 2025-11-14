using Test
using Graphs
using NetworkBrokerage

@testset "Investment Tests" begin
    @testset "Investment proportions sum to 1" begin
        # For an undirected graph, investments from a node should sum to 1
        g = star_graph(5)

        # Sum investments from center node
        total = 0.0
        for j in neighbors(g, 1)
            total += NetworkBrokerage.investment(g, 1, j)
        end

        @test total ≈ 1.0 atol=1e-10
    end

    @testset "Investment in cycle graph" begin
        # In a cycle, each node invests equally in its neighbors
        g = cycle_graph(4)

        # Node 1 has neighbors 2 and 4
        inv_1_2 = NetworkBrokerage.investment(g, 1, 2)
        inv_1_4 = NetworkBrokerage.investment(g, 1, 4)

        @test inv_1_2 ≈ 0.5 atol=1e-10
        @test inv_1_4 ≈ 0.5 atol=1e-10
        @test inv_1_2 ≈ inv_1_4 atol=1e-10
    end

    @testset "Investment in star graph" begin
        # In a star, center invests equally in all peripheral nodes
        g = star_graph(5)

        inv_1_2 = NetworkBrokerage.investment(g, 1, 2)
        inv_1_3 = NetworkBrokerage.investment(g, 1, 3)

        @test inv_1_2 ≈ inv_1_3 atol=1e-10
        @test inv_1_2 ≈ 0.25 atol=1e-10  # 1/4 for 4 neighbors
    end

    @testset "Investment with isolated node" begin
        g = Graph(3)
        add_edge!(g, 1, 2)
        # Node 3 is isolated

        # Investment from isolated node should be 0
        @test NetworkBrokerage.investment(g, 3, 1) == 0.0
        @test NetworkBrokerage.investment(g, 3, 2) == 0.0
    end

    @testset "Investment sum calculations" begin
        # Create a simple triangle
        g = Graph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        # Investment sum from 1 to 2 through 3
        inv_sum = NetworkBrokerage.investment_sum(g, 1, 2)

        @test inv_sum isa Float64
        @test inv_sum >= 0.0
        @test inv_sum <= 1.0
    end
end
