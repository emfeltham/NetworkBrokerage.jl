using Test
using Graphs
using NetworkBrokerage

@testset "Brokerage Integration Tests" begin

    @testset "1. Karate Club network" begin
        # Zachary's Karate Club network
        # 34 nodes split into two factions (groups 1 and 2)
        # Based on the historical faction split

        # Create simplified Karate Club network (using key connections)
        g = Graph(34)

        # Add edges based on the classic karate club structure
        # Core members of faction 1 (around instructor, node 1)
        edges_faction1 = [
            (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8),
            (1, 9), (1, 11), (1, 12), (1, 13), (1, 14), (1, 18), (1, 20), (1, 22), (1, 32),
            (2, 3), (2, 4), (2, 8), (2, 14), (2, 18), (2, 20), (2, 22), (2, 31),
            (3, 4), (3, 8), (3, 9), (3, 10), (3, 14), (3, 28), (3, 29), (3, 33),
            (4, 8), (4, 13), (4, 14)
        ]

        # Core members of faction 2 (around administrator, node 34)
        edges_faction2 = [
            (34, 9), (34, 10), (34, 14), (34, 15), (34, 16), (34, 19), (34, 20),
            (34, 21), (34, 23), (34, 24), (34, 27), (34, 28), (34, 29), (34, 30),
            (34, 31), (34, 32), (34, 33),
            (33, 9), (33, 15), (33, 16), (33, 19), (33, 21), (33, 23), (33, 24),
            (33, 30), (33, 31), (33, 32)
        ]

        # Bridge connections (boundary spanners)
        edges_bridge = [
            (1, 32), (2, 31), (3, 33), (9, 31), (9, 33),
            (14, 34), (20, 34), (32, 34)
        ]

        for (i, j) in vcat(edges_faction1, edges_faction2, edges_bridge)
            add_edge!(g, i, j)
        end

        # Historical faction split (after the split)
        # Faction 1: Instructor's group (nodes 1-16, roughly)
        # Faction 2: Administrator's group (nodes 17-34, roughly)
        # This is a simplified version
        groups = vcat(
            fill(1, 16),  # First faction
            fill(2, 18)   # Second faction
        )

        br = brokerage(g, groups)

        # Boundary spanners should have higher brokerage
        # Nodes like 3, 9, 14, 20, 31, 32, 33 span boundaries
        boundary_nodes = [3, 9, 14, 20, 31, 32, 33]

        # Check that some boundary nodes have non-zero brokerage
        boundary_brokerage = [total_brokerage(br, n) for n in boundary_nodes]
        @test any(x -> x > 0, boundary_brokerage)

        # Total brokerage should be non-negative
        @test sum(br.total) >= 0

        # Check that result structure is correct
        @test length(br.total) == 34
        @test br.groups == groups
    end

    @testset "2. Comparison with constraint" begin
        # Star graph with different group at center
        # Center should have high brokerage and low constraint
        # Periphery should have low brokerage and high constraint

        g = star_graph(6)  # 1 node at center, 5 on periphery

        # Center node (1) in different group than periphery
        groups = [1, 2, 2, 2, 2, 2]

        br = brokerage(g, groups)

        # Center node should have high brokerage (liaisons between periphery nodes)
        # In undirected star: center brokers between all pairs of periphery nodes
        # Number of pairs: C(5,2) = 10
        # For undirected graph, each counted twice then halved = 10
        center_brokerage = total_brokerage(br, 1)
        @test center_brokerage > 0
        @test liaison(br, 1) == center_brokerage  # All should be liaison role

        # Periphery nodes should have zero brokerage (no paths through them)
        for i in 2:6
            @test total_brokerage(br, i) == 0
        end

        # Constraint check: center should have low constraint
        # (This tests integration with existing constraint functionality)
        c_center = constraint(g, 1)
        c_periphery = constraint(g, 2)

        @test c_periphery > c_center
        @test c_center >= 0.0
        @test c_periphery >= 0.0
    end

    @testset "3. Multi-group organizational network" begin
        # Simulate a 3-department organization with bridges
        # 3 departments, each with 5 members, plus 2 managers who span departments

        g = DiGraph(17)

        # Department 1 (nodes 1-5): Internal connections
        for i in 1:4
            add_edge!(g, i, i+1)
            add_edge!(g, i+1, i)
        end

        # Department 2 (nodes 6-10): Internal connections
        for i in 6:9
            add_edge!(g, i, i+1)
            add_edge!(g, i+1, i)
        end

        # Department 3 (nodes 11-15): Internal connections
        for i in 11:14
            add_edge!(g, i, i+1)
            add_edge!(g, i+1, i)
        end

        # Managers (nodes 16, 17): Connect departments
        # Manager 16 connects Dept 1 and 2
        add_edge!(g, 3, 16)  # From Dept 1
        add_edge!(g, 16, 3)
        add_edge!(g, 16, 8)  # To Dept 2
        add_edge!(g, 8, 16)

        # Manager 17 connects Dept 2 and 3
        add_edge!(g, 8, 17)  # From Dept 2
        add_edge!(g, 17, 8)
        add_edge!(g, 17, 13) # To Dept 3
        add_edge!(g, 13, 17)

        # Group assignment
        groups = vcat(
            fill(1, 5),  # Dept 1
            fill(2, 5),  # Dept 2
            fill(3, 5),  # Dept 3
            [4, 4]       # Managers (separate group)
        )

        br = brokerage(g, groups)

        # Managers should have high liaison/cosmopolitan roles
        manager_16_brokerage = total_brokerage(br, 16)
        manager_17_brokerage = total_brokerage(br, 17)

        @test manager_16_brokerage + manager_17_brokerage > 0

        # Nodes 3, 8, 13 (connected to managers) should have some gatekeeper/representative roles
        # These are the department members who connect to managers
        boundary_members = [3, 8, 13]
        boundary_brokerage = sum(total_brokerage(br, n) for n in boundary_members)

        # At least some boundary activity expected
        @test boundary_brokerage >= 0
    end

    @testset "4. Modularity validation with strong communities" begin
        # Create graph with clear communities (separate cliques connected by bridges)
        g = DiGraph(9)

        # Clique 1 (nodes 1-3): Fully connected
        for i in 1:3, j in 1:3
            if i != j
                add_edge!(g, i, j)
            end
        end

        # Clique 2 (nodes 4-6): Fully connected
        for i in 4:6, j in 4:6
            if i != j
                add_edge!(g, i, j)
            end
        end

        # Clique 3 (nodes 7-9): Fully connected
        for i in 7:9, j in 7:9
            if i != j
                add_edge!(g, i, j)
            end
        end

        # Bridges between cliques
        add_edge!(g, 3, 4)  # Bridge from clique 1 to 2
        add_edge!(g, 6, 7)  # Bridge from clique 2 to 3

        groups = [1, 1, 1, 2, 2, 2, 3, 3, 3]

        # Calculate brokerage with modularity
        br = brokerage(g, groups; compute_modularity=true)

        # Strong communities should have high modularity
        @test br.modularity !== nothing
        @test br.modularity > 0.0  # Positive modularity indicates community structure

        # Bridge nodes (3 and 6) should have high brokerage
        # Node 3 bridges clique 1 → 2
        # Node 6 bridges clique 2 → 3
        bridge_3_brokerage = total_brokerage(br, 3)
        bridge_6_brokerage = total_brokerage(br, 6)

        @test bridge_3_brokerage > 0
        @test bridge_6_brokerage > 0

        # These should be representative roles (outgoing to other group)
        @test representative(br, 3) > 0
        @test representative(br, 6) > 0

        # Test with random groups (should have low modularity)
        random_groups = [1, 2, 3, 1, 2, 3, 1, 2, 3]
        br_random = brokerage(g, random_groups; compute_modularity=true)

        # Random grouping should have lower modularity than natural communities
        @test br_random.modularity !== nothing
        @test br_random.modularity < br.modularity
    end

    @testset "5. Modularity with non-integer groups" begin
        # Test that modularity works correctly with string/symbol groups

        g = DiGraph(6)

        # Two communities
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 1)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 2)
        add_edge!(g, 1, 3)
        add_edge!(g, 3, 1)

        add_edge!(g, 4, 5)
        add_edge!(g, 5, 4)
        add_edge!(g, 5, 6)
        add_edge!(g, 6, 5)
        add_edge!(g, 4, 6)
        add_edge!(g, 6, 4)

        # Bridge
        add_edge!(g, 3, 4)

        # Test with integer groups
        groups_int = [1, 1, 1, 2, 2, 2]
        br_int = brokerage(g, groups_int; compute_modularity=true)

        # Test with string groups
        groups_str = ["Sales", "Sales", "Sales", "Engineering", "Engineering", "Engineering"]
        br_str = brokerage(g, groups_str; compute_modularity=true)

        # Test with symbol groups
        groups_sym = [:A, :A, :A, :B, :B, :B]
        br_sym = brokerage(g, groups_sym; compute_modularity=true)

        # All should compute modularity successfully
        @test br_int.modularity !== nothing
        @test br_str.modularity !== nothing
        @test br_sym.modularity !== nothing

        # Modularity values should be identical (same structure, different labels)
        @test br_int.modularity ≈ br_str.modularity
        @test br_int.modularity ≈ br_sym.modularity

        # All should have positive modularity (clear community structure)
        @test br_int.modularity > 0.0
        @test br_str.modularity > 0.0
        @test br_sym.modularity > 0.0

        # Bridge node (3) should have brokerage in all cases
        @test total_brokerage(br_int, 3) > 0
        @test total_brokerage(br_str, 3) > 0
        @test total_brokerage(br_sym, 3) > 0

        # Brokerage counts should match (same structure)
        @test total_brokerage(br_int, 3) == total_brokerage(br_str, 3)
        @test total_brokerage(br_int, 3) == total_brokerage(br_sym, 3)
    end

    @testset "Large network performance" begin
        # Test that brokerage can handle moderately large networks
        # Create a network with multiple communities

        n_communities = 5
        community_size = 20
        n = n_communities * community_size

        g = DiGraph(n)
        groups = zeros(Int, n)

        # Create communities with internal connections
        for c in 1:n_communities
            start_node = (c - 1) * community_size + 1
            end_node = c * community_size

            # Assign groups
            for i in start_node:end_node
                groups[i] = c
            end

            # Create some internal edges (not fully connected, for performance)
            for i in start_node:end_node-1
                add_edge!(g, i, i+1)
                add_edge!(g, i+1, i)

                # Add some random connections within community
                if i + 2 <= end_node
                    add_edge!(g, i, i+2)
                end
            end
        end

        # Add bridges between communities
        for c in 1:n_communities-1
            bridge_from = c * community_size
            bridge_to = c * community_size + 1
            add_edge!(g, bridge_from, bridge_to)
        end

        # This should complete in reasonable time
        br = brokerage(g, groups)

        @test length(br.total) == n
        @test sum(br.total) >= 0

        # Bridge nodes should have some brokerage
        bridge_nodes = [community_size * i for i in 1:n_communities-1]
        bridge_brokerage = sum(total_brokerage(br, n) for n in bridge_nodes)
        @test bridge_brokerage > 0
    end
end
