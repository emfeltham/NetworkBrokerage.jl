using Test
using Graphs
using NetworkConstraint

@testset "Constraint Tests" begin
    @testset "Basic constraint calculations" begin
        # Star graph: center node has high constraint, peripheral nodes have low
        g = star_graph(5)

        # Center node (1) should have lower constraint than peripheral nodes
        c_center = constraint(g, 1)
        c_peripheral = constraint(g, 2)

        @test c_center isa Float64
        @test c_peripheral isa Float64
        @test c_peripheral > c_center  # Peripheral nodes more constrained
        @test c_center >= 0.0
        @test c_peripheral >= 0.0
    end

    @testset "Cycle graph constraint" begin
        # In a cycle, all nodes have equal constraint
        g = cycle_graph(5)

        c1 = constraint(g, 1)
        c2 = constraint(g, 2)
        c3 = constraint(g, 3)

        @test c1 ≈ c2 atol=1e-10
        @test c2 ≈ c3 atol=1e-10
        @test c1 > 0.0
    end

    @testset "Complete graph constraint" begin
        # Complete graph: all nodes equally connected
        g = complete_graph(4)

        c1 = constraint(g, 1)
        c2 = constraint(g, 2)

        @test c1 ≈ c2 atol=1e-10
        @test c1 > 0.0
    end

    @testset "Isolated node" begin
        # Graph with an isolated node
        g = Graph(5)
        add_edge!(g, 1, 2)
        add_edge!(g, 1, 3)
        # Node 5 is isolated

        @test constraint(g, 5) == 0.0
    end

    @testset "Path graph constraint" begin
        # Linear path
        g = path_graph(5)

        # End nodes have higher constraint than middle nodes
        c_end = constraint(g, 1)
        c_middle = constraint(g, 3)

        @test c_end > c_middle
        @test c_end > 0.0
        @test c_middle > 0.0
    end
end
