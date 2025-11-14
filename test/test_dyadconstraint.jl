using Test
using Graphs
using NetworkConstraint

@testset "Dyadic Constraint Tests" begin
    @testset "Basic dyadic constraint" begin
        # Simple triangle
        g = Graph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 1, 3)

        dc_12 = dyadconstraint(g, 1, 2)
        dc_13 = dyadconstraint(g, 1, 3)

        @test dc_12 isa Float64
        @test dc_13 isa Float64
        @test dc_12 >= 0.0
        @test dc_13 >= 0.0
        @test dc_12 <= 1.0
        @test dc_13 <= 1.0
    end

    @testset "Dyadic constraint with edge object" begin
        g = cycle_graph(4)

        # Test with edge object
        e = Edge(1, 2)
        dc = dyadconstraint(g, e)

        @test dc isa Float64
        @test dc >= 0.0
        @test dc <= 1.0
    end

    @testset "Dyadic constraint non-neighbors" begin
        # Path graph: nodes 1 and 3 are not directly connected but share node 2
        g = path_graph(5)

        # Dyadic constraint can be non-zero due to indirect investment through mutual neighbors
        dc_13 = dyadconstraint(g, 1, 3)

        @test dc_13 > 0.0  # Non-zero due to indirect path through node 2

        # For nodes with no mutual neighbors, constraint should be 0
        g2 = Graph(4)
        add_edge!(g2, 1, 2)
        add_edge!(g2, 3, 4)
        # Nodes 1 and 3 have no connection and no mutual neighbors

        dc_no_mutual = dyadconstraint(g2, 1, 3)
        @test dc_no_mutual == 0.0
    end

    @testset "Dyadic constraint symmetry in undirected graphs" begin
        g = cycle_graph(5)

        dc_12 = dyadconstraint(g, 1, 2)
        dc_21 = dyadconstraint(g, 2, 1)

        # Should be symmetric for undirected graphs
        @test dc_12 ≈ dc_21 atol=1e-10
    end

    @testset "Sum of dyadic constraints equals total constraint" begin
        g = star_graph(5)

        # Total constraint should equal sum of dyadic constraints
        c_total = constraint(g, 1)
        c_sum = sum(dyadconstraint(g, 1, j) for j in neighbors(g, 1))

        @test c_total ≈ c_sum atol=1e-10
    end
end
