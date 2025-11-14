using Test
using Graphs
using SimpleWeightedGraphs
using NetworkBrokerage

@testset "Weighted Undirected Graph Tests" begin
    @testset "Basic weighted investment calculations" begin
        # Simple weighted triangle
        wg = SimpleWeightedGraph(3)
        add_edge!(wg, 1, 2, 2.0)
        add_edge!(wg, 1, 3, 1.0)

        # Investment should be proportional to weights
        inv_12 = NetworkBrokerage.investment(wg, 1, 2)
        inv_13 = NetworkBrokerage.investment(wg, 1, 3)

        @test inv_12 ≈ 2.0/3.0 atol=1e-10  # 2/(2+1)
        @test inv_13 ≈ 1.0/3.0 atol=1e-10  # 1/(2+1)
        @test inv_12 + inv_13 ≈ 1.0 atol=1e-10
    end

    @testset "Weighted star graph - uniform weights" begin
        # Star with uniform weights
        wg = SimpleWeightedGraph(5)
        for i in 2:5
            add_edge!(wg, 1, i, 1.0)
        end

        # Should behave like unweighted star
        c_center = constraint(wg, 1)
        c_spoke = constraint(wg, 2)

        @test c_center isa Float64
        @test c_spoke isa Float64
        @test c_spoke > c_center  # Spokes more constrained
        @test c_spoke ≈ 1.0 atol=1e-10  # Single connection, full constraint
    end

    @testset "Weighted star graph - non-uniform weights" begin
        # Star with varying weights
        wg = SimpleWeightedGraph(4)
        add_edge!(wg, 1, 2, 3.0)
        add_edge!(wg, 1, 3, 2.0)
        add_edge!(wg, 1, 4, 1.0)

        # Center's investment is weighted
        inv_12 = NetworkBrokerage.investment(wg, 1, 2)
        inv_13 = NetworkBrokerage.investment(wg, 1, 3)
        inv_14 = NetworkBrokerage.investment(wg, 1, 4)

        @test inv_12 ≈ 3.0/6.0 atol=1e-10  # 3/(3+2+1)
        @test inv_13 ≈ 2.0/6.0 atol=1e-10  # 2/(3+2+1)
        @test inv_14 ≈ 1.0/6.0 atol=1e-10  # 1/(3+2+1)

        # Constraint should reflect weighted investments
        c_center = constraint(wg, 1)
        @test c_center > 0.0
        @test c_center < 1.0  # Multiple disconnected alters = lower constraint
    end

    @testset "Weighted cycle graph - uniform weights" begin
        # Cycle with uniform weights
        wg = SimpleWeightedGraph(4)
        add_edge!(wg, 1, 2, 1.0)
        add_edge!(wg, 2, 3, 1.0)
        add_edge!(wg, 3, 4, 1.0)
        add_edge!(wg, 4, 1, 1.0)

        # All nodes should have equal constraint (symmetry)
        c1 = constraint(wg, 1)
        c2 = constraint(wg, 2)
        c3 = constraint(wg, 3)
        c4 = constraint(wg, 4)

        @test c1 ≈ c2 atol=1e-10
        @test c2 ≈ c3 atol=1e-10
        @test c3 ≈ c4 atol=1e-10
    end

    @testset "Weighted cycle graph - non-uniform weights" begin
        # Cycle with varying weights
        wg = SimpleWeightedGraph(4)
        add_edge!(wg, 1, 2, 3.0)
        add_edge!(wg, 2, 3, 1.0)
        add_edge!(wg, 3, 4, 1.0)
        add_edge!(wg, 4, 1, 1.0)

        # Node 1 invests more in node 2
        inv_12 = NetworkBrokerage.investment(wg, 1, 2)
        inv_14 = NetworkBrokerage.investment(wg, 1, 4)

        @test inv_12 ≈ 3.0/4.0 atol=1e-10  # 3/(3+1)
        @test inv_14 ≈ 1.0/4.0 atol=1e-10  # 1/(3+1)
        @test inv_12 > inv_14  # Heavier edge gets more investment

        # Constraint should reflect this imbalance
        c1 = constraint(wg, 1)
        @test c1 > 0.0
    end

    @testset "Weighted triangle - testing closure" begin
        # Complete triangle with uniform weights
        wg = SimpleWeightedGraph(3)
        add_edge!(wg, 1, 2, 1.0)
        add_edge!(wg, 2, 3, 1.0)
        add_edge!(wg, 1, 3, 1.0)

        # Each node has two neighbors, fully connected
        # High closure = high constraint
        c1 = constraint(wg, 1)
        c2 = constraint(wg, 2)

        @test c1 ≈ c2 atol=1e-10  # Symmetry
        @test c1 ≈ 1.125 atol=1e-10  # Known value for triangle
    end

    @testset "Weighted triangle - non-uniform weights" begin
        # Triangle with varying weights
        wg = SimpleWeightedGraph(3)
        add_edge!(wg, 1, 2, 4.0)
        add_edge!(wg, 2, 3, 2.0)
        add_edge!(wg, 1, 3, 1.0)

        # Node 1 invests more in node 2 than node 3
        inv_12 = NetworkBrokerage.investment(wg, 1, 2)
        inv_13 = NetworkBrokerage.investment(wg, 1, 3)

        @test inv_12 ≈ 4.0/5.0 atol=1e-10  # 4/(4+1)
        @test inv_13 ≈ 1.0/5.0 atol=1e-10  # 1/(4+1)

        # Dyadic constraint from node 2 on node 1
        # Should include both direct and indirect (through node 3)
        dc_12 = dyadconstraint(wg, 1, 2)
        @test dc_12 > (inv_12)^2  # Indirect paths add constraint
    end

    @testset "Weighted path graph" begin
        # Linear path with varying weights
        wg = SimpleWeightedGraph(4)
        add_edge!(wg, 1, 2, 2.0)
        add_edge!(wg, 2, 3, 1.0)
        add_edge!(wg, 3, 4, 1.0)

        # End nodes have single connection = high constraint
        c_end = constraint(wg, 1)
        @test c_end ≈ 1.0 atol=1e-10  # Single neighbor, full constraint

        # Middle nodes have lower constraint
        c_middle = constraint(wg, 2)
        @test c_middle < 1.0  # Multiple neighbors reduces constraint
        @test c_middle > 0.0
    end

    @testset "Weighted complete graph" begin
        # Complete graph with uniform weights
        wg = SimpleWeightedGraph(4)
        for i in 1:4
            for j in (i+1):4
                add_edge!(wg, i, j, 1.0)
            end
        end

        # All nodes should have equal constraint
        c1 = constraint(wg, 1)
        c2 = constraint(wg, 2)
        c3 = constraint(wg, 3)

        @test c1 ≈ c2 atol=1e-10
        @test c2 ≈ c3 atol=1e-10

        # High closure = high constraint
        @test c1 > 0.5
    end

    @testset "Weighted complete graph - non-uniform weights" begin
        # Complete graph with varying weights
        wg = SimpleWeightedGraph(3)
        add_edge!(wg, 1, 2, 3.0)
        add_edge!(wg, 2, 3, 2.0)
        add_edge!(wg, 1, 3, 1.0)

        # Should not have perfect symmetry
        c1 = constraint(wg, 1)
        c2 = constraint(wg, 2)
        c3 = constraint(wg, 3)

        @test c1 isa Float64
        @test c2 isa Float64
        @test c3 isa Float64

        # All positive (fully connected)
        @test c1 > 0.0
        @test c2 > 0.0
        @test c3 > 0.0
    end

    @testset "Constraint decomposition property" begin
        # Constraint should equal sum of dyadic constraints
        wg = SimpleWeightedGraph(4)
        add_edge!(wg, 1, 2, 2.0)
        add_edge!(wg, 1, 3, 1.5)
        add_edge!(wg, 1, 4, 1.0)

        c_total = constraint(wg, 1)
        c_sum = sum(dyadconstraint(wg, 1, j) for j in neighbors(wg, 1))

        @test c_total ≈ c_sum atol=1e-10
    end

    @testset "Investment proportions sum to 1" begin
        # For any weighted node, investments should sum to 1
        wg = SimpleWeightedGraph(5)
        add_edge!(wg, 1, 2, 5.0)
        add_edge!(wg, 1, 3, 3.0)
        add_edge!(wg, 1, 4, 2.0)
        add_edge!(wg, 1, 5, 1.0)

        total = sum(NetworkBrokerage.investment(wg, 1, j) for j in neighbors(wg, 1))
        @test total ≈ 1.0 atol=1e-10
    end

    @testset "Very large weights" begin
        # Test numerical stability with large weights
        wg = SimpleWeightedGraph(3)
        add_edge!(wg, 1, 2, 1e6)
        add_edge!(wg, 1, 3, 1e6)

        inv_12 = NetworkBrokerage.investment(wg, 1, 2)
        inv_13 = NetworkBrokerage.investment(wg, 1, 3)

        @test inv_12 ≈ 0.5 atol=1e-10  # Should be equal
        @test inv_13 ≈ 0.5 atol=1e-10
        @test inv_12 + inv_13 ≈ 1.0 atol=1e-10
    end

    @testset "Very small weights" begin
        # Test numerical stability with small weights
        wg = SimpleWeightedGraph(3)
        add_edge!(wg, 1, 2, 1e-6)
        add_edge!(wg, 1, 3, 1e-6)

        inv_12 = NetworkBrokerage.investment(wg, 1, 2)
        inv_13 = NetworkBrokerage.investment(wg, 1, 3)

        @test inv_12 ≈ 0.5 atol=1e-10  # Should be equal
        @test inv_13 ≈ 0.5 atol=1e-10
        @test inv_12 + inv_13 ≈ 1.0 atol=1e-10
    end

    @testset "Mixed weight magnitudes" begin
        # Test with very different weight magnitudes
        wg = SimpleWeightedGraph(3)
        add_edge!(wg, 1, 2, 1000.0)
        add_edge!(wg, 1, 3, 1.0)

        # Heavy edge should dominate
        inv_12 = NetworkBrokerage.investment(wg, 1, 2)
        inv_13 = NetworkBrokerage.investment(wg, 1, 3)

        @test inv_12 ≈ 1000.0/1001.0 atol=1e-10
        @test inv_13 ≈ 1.0/1001.0 atol=1e-10
        @test inv_12 > 0.99  # Almost all investment in heavy edge

        # Constraint should be close to 1 (single dominant tie)
        c1 = constraint(wg, 1)
        @test c1 > 0.99
    end

    @testset "Isolated node in weighted graph" begin
        # Weighted graph with isolated node
        wg = SimpleWeightedGraph(4)
        add_edge!(wg, 1, 2, 2.0)
        add_edge!(wg, 2, 3, 1.5)
        # Node 4 is isolated

        c_isolated = constraint(wg, 4)
        @test c_isolated == 0.0
    end

    @testset "Weighted dyadic constraint symmetry" begin
        # For undirected graphs with equal degrees, dyadic constraint should be symmetric
        # Use a cycle where all nodes have degree 2
        wg = SimpleWeightedGraph(4)
        add_edge!(wg, 1, 2, 2.0)
        add_edge!(wg, 2, 3, 2.0)
        add_edge!(wg, 3, 4, 2.0)
        add_edge!(wg, 4, 1, 2.0)

        dc_12 = dyadconstraint(wg, 1, 2)
        dc_21 = dyadconstraint(wg, 2, 1)

        # Symmetric because all nodes have same degree and weights
        @test dc_12 ≈ dc_21 atol=1e-10
    end

    @testset "Weighted investment_sum calculation" begin
        # Test indirect investment calculation
        wg = SimpleWeightedGraph(3)
        add_edge!(wg, 1, 2, 2.0)
        add_edge!(wg, 2, 3, 1.0)
        add_edge!(wg, 1, 3, 1.0)

        # Indirect investment from 1 to 2 through 3
        inv_sum = NetworkBrokerage.investment_sum(wg, 1, 2)

        # Should be inv(1,3) * inv(3,2)
        inv_13 = NetworkBrokerage.investment(wg, 1, 3)
        inv_32 = NetworkBrokerage.investment(wg, 3, 2)
        expected = inv_13 * inv_32

        @test inv_sum ≈ expected atol=1e-10
    end

    @testset "Comparison: weighted vs unweighted" begin
        # Weighted with uniform weights should match unweighted
        wg = SimpleWeightedGraph(4)
        add_edge!(wg, 1, 2, 1.0)
        add_edge!(wg, 1, 3, 1.0)
        add_edge!(wg, 1, 4, 1.0)

        g = Graph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 1, 3)
        add_edge!(g, 1, 4)

        c_weighted = constraint(wg, 1)
        c_unweighted = constraint(g, 1)

        @test c_weighted ≈ c_unweighted atol=1e-10
    end
end
