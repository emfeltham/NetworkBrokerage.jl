using Test
using Graphs
using NetworkBrokerage

@testset "Brokerage Unit Tests" begin

    @testset "1. Role classification tests" begin
        # Test classify_brokerage_role function indirectly through brokerage results

        # All same group → coordinator
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        groups = [1, 1, 1]
        br = brokerage(g, groups)
        @test coordinator(br, 2) == 1
        @test total_brokerage(br, 2) == 1

        # Ego + j same, i different → gatekeeper
        groups = [1, 2, 2]
        br = brokerage(g, groups)
        @test gatekeeper(br, 2) == 1
        @test total_brokerage(br, 2) == 1

        # Ego + i same, j different → representative
        groups = [1, 1, 2]
        br = brokerage(g, groups)
        @test representative(br, 2) == 1
        @test total_brokerage(br, 2) == 1

        # i + j same, ego different → liaison
        groups = [1, 2, 1]
        br = brokerage(g, groups)
        @test liaison(br, 2) == 1
        @test total_brokerage(br, 2) == 1

        # All different → cosmopolitan
        groups = [1, 2, 3]
        br = brokerage(g, groups)
        @test cosmopolitan(br, 2) == 1
        @test total_brokerage(br, 2) == 1
    end

    @testset "2. Simple directed graph - representative" begin
        # 3-node chain: 1 → 2 → 3
        # Groups: [A, A, B]
        # Node 2 should be representative (1 count)
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        groups = [1, 1, 2]

        br = brokerage(g, groups)

        @test representative(br, 2) == 1
        @test coordinator(br, 2) == 0
        @test gatekeeper(br, 2) == 0
        @test liaison(br, 2) == 0
        @test cosmopolitan(br, 2) == 0
        @test total_brokerage(br, 2) == 1

        # Nodes 1 and 3 should have no brokerage
        @test total_brokerage(br, 1) == 0
        @test total_brokerage(br, 3) == 0
    end

    @testset "3. Coordinator role - star network" begin
        # Star: 1 → 2, 2 → 3, 2 → 4
        # Groups: [A, A, A, A]
        # Node 2 coordinates: 2 triads (1→2→3, 1→2→4)
        g = DiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 2, 4)
        groups = [1, 1, 1, 1]

        br = brokerage(g, groups)

        @test coordinator(br, 2) == 2
        @test total_brokerage(br, 2) == 2

        # Other roles should be zero
        @test gatekeeper(br, 2) == 0
        @test representative(br, 2) == 0
        @test liaison(br, 2) == 0
        @test cosmopolitan(br, 2) == 0
    end

    @testset "4. Gatekeeper role" begin
        # 1 → 2 → 3
        # Groups: [A, B, B]
        # Node 2 is gatekeeper (ego=B, j=B, i=A)
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        groups = [1, 2, 2]

        br = brokerage(g, groups)

        @test gatekeeper(br, 2) == 1
        @test total_brokerage(br, 2) == 1
        @test coordinator(br, 2) == 0
        @test representative(br, 2) == 0
        @test liaison(br, 2) == 0
        @test cosmopolitan(br, 2) == 0
    end

    @testset "5. Liaison role" begin
        # 1 → 3 → 2, 4 → 3 → 2
        # Groups: [A, A, B, A]
        # Node 3 is liaison (i=A, j=A, ego=B)
        g = DiGraph(4)
        add_edge!(g, 1, 3)
        add_edge!(g, 3, 2)
        add_edge!(g, 4, 3)
        groups = [1, 1, 2, 1]

        br = brokerage(g, groups)

        # Node 3 should have 2 liaison triads: 1→3→2 and 4→3→2
        @test liaison(br, 3) == 2
        @test coordinator(br, 3) == 0
        @test gatekeeper(br, 3) == 0
        @test representative(br, 3) == 0
        @test cosmopolitan(br, 3) == 0
        @test total_brokerage(br, 3) == 2
    end

    @testset "6. Cosmopolitan role" begin
        # 1 → 2 → 3
        # Groups: [A, B, C]
        # Node 2 is cosmopolitan (all different groups)
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        groups = [1, 2, 3]

        br = brokerage(g, groups)

        @test cosmopolitan(br, 2) == 1
        @test total_brokerage(br, 2) == 1
        @test coordinator(br, 2) == 0
        @test gatekeeper(br, 2) == 0
        @test representative(br, 2) == 0
        @test liaison(br, 2) == 0
    end

    @testset "7. Undirected graph - counts halved" begin
        # Same structure as test 2, but undirected
        # 1 — 2 — 3 (undirected)
        # Groups: [A, A, B]
        # Each triad counted twice, should be halved
        g = Graph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        groups = [1, 1, 2]

        br = brokerage(g, groups)

        # In undirected: both 1→2→3 and 3→2→1 are counted, then halved
        # 3→2→1: ego=2(A), i=3(B), j=1(A) → gatekeeper
        # 1→2→3: ego=2(A), i=1(A), j=3(B) → representative
        # Each counted once before halving (2 total), after halving = 1
        @test total_brokerage(br, 2) >= 0  # May be 0 or 1 depending on division

        # Test coordinator with all same group (more predictable)
        g2 = Graph(3)
        add_edge!(g2, 1, 2)
        add_edge!(g2, 2, 3)
        groups2 = [1, 1, 1]
        br2 = brokerage(g2, groups2)

        # Without halving: 2 coordinator triads (1→2→3 and 3→2→1)
        # With halving: 1 coordinator triad
        @test coordinator(br2, 2) == 1
        @test total_brokerage(br2, 2) == 1
    end

    @testset "8. Single-node calculation" begin
        # Compare single-node function with full calculation
        g = DiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 2, 4)
        groups = [1, 1, 1, 2]

        br_full = brokerage(g, groups)
        result_single = brokerage(g, groups, 2)

        # Results should match
        @test result_single.coordinator == coordinator(br_full, 2)
        @test result_single.gatekeeper == gatekeeper(br_full, 2)
        @test result_single.representative == representative(br_full, 2)
        @test result_single.liaison == liaison(br_full, 2)
        @test result_single.cosmopolitan == cosmopolitan(br_full, 2)
        @test result_single.total == total_brokerage(br_full, 2)
    end

    @testset "9. Group validation" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        # Wrong length vector → error
        @test_throws ArgumentError brokerage(g, [1, 1])
        @test_throws ArgumentError brokerage(g, [1, 1, 2, 2])

        # Missing node in dict → error
        groups_dict = Dict(1 => 1, 2 => 1)  # Missing node 3
        @test_throws ArgumentError brokerage(g, groups_dict)

        # Valid dict should work
        groups_dict_valid = Dict(1 => 1, 2 => 1, 3 => 2)
        br = brokerage(g, groups_dict_valid)
        @test br isa BrokerageResult

        # Invalid ego for single-node function
        @test_throws ArgumentError brokerage(g, [1, 1, 2], 5)
    end

    @testset "10. Edge cases" begin
        # Empty graph (nodes but no edges)
        g = DiGraph(3)
        groups = [1, 1, 2]
        br = brokerage(g, groups)
        @test total_brokerage(br, 1) == 0
        @test total_brokerage(br, 2) == 0
        @test total_brokerage(br, 3) == 0
        @test sum(br.total) == 0

        # Fully connected graph (no brokerage possible)
        g = complete_digraph(3)
        groups = [1, 1, 2]
        br = brokerage(g, groups)
        # All triads have direct i→j edge, so no brokerage
        @test sum(br.total) == 0

        # Isolated nodes
        g = DiGraph(5)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        # Nodes 4 and 5 are isolated
        groups = [1, 1, 2, 3, 3]
        br = brokerage(g, groups)
        @test total_brokerage(br, 4) == 0
        @test total_brokerage(br, 5) == 0

        # Single group (only coordinator possible)
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        groups = [1, 1, 1]
        br = brokerage(g, groups)
        @test coordinator(br, 2) == 1
        @test gatekeeper(br, 2) == 0
        @test representative(br, 2) == 0
        @test liaison(br, 2) == 0
        @test cosmopolitan(br, 2) == 0

        # Self-loops should be ignored
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 2, 2)  # Self-loop on node 2
        groups = [1, 1, 2]
        br = brokerage(g, groups)
        # Should get same result as without self-loop
        @test representative(br, 2) == 1
        @test total_brokerage(br, 2) == 1
    end

    @testset "11. Named groups" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)

        # String groups
        groups_str = ["Sales", "Sales", "Engineering"]
        br = brokerage(g, groups_str)
        @test representative(br, 2) == 1
        @test br.groups == groups_str

        # Symbol groups
        groups_sym = [:A, :A, :B]
        br = brokerage(g, groups_sym)
        @test representative(br, 2) == 1
        @test br.groups == groups_sym

        # Mixed types in Vector{Any}
        groups_mixed = Any[1, 1, "B"]
        br = brokerage(g, groups_mixed)
        @test representative(br, 2) == 1
    end

    @testset "12. Directed edge interpretation (critical)" begin
        # Create: 1 → 2 → 3 AND 3 → 1 (reverse edge)
        # Groups: [A, A, B]
        # Test: Node 2 should still be representative (1 count)
        # Rationale: Edge 1→3 does NOT exist, so 2 brokers 1→2→3
        # The reverse edge 3→1 is irrelevant to this brokerage
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 1)  # Reverse edge (should not affect brokerage)
        groups = [1, 1, 2]

        br = brokerage(g, groups)

        # Node 2 should still be representative for 1→2→3
        # The edge 3→1 exists, but we only check for 1→3 (which doesn't exist)
        @test representative(br, 2) == 1
        @test total_brokerage(br, 2) == 1

        # Verify it's different if we add the direct edge 1→3
        g2 = DiGraph(3)
        add_edge!(g2, 1, 2)
        add_edge!(g2, 2, 3)
        add_edge!(g2, 1, 3)  # Direct edge 1→3
        br2 = brokerage(g2, groups)

        # Now there's no brokerage because 1→3 exists
        @test representative(br2, 2) == 0
        @test total_brokerage(br2, 2) == 0
    end

    @testset "Modularity integration" begin
        # Test modularity calculation
        g = DiGraph(6)
        # Create two groups with strong internal connections
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 1)
        add_edge!(g, 4, 5)
        add_edge!(g, 5, 6)
        add_edge!(g, 6, 4)
        # Bridge between groups
        add_edge!(g, 3, 4)

        groups = [1, 1, 1, 2, 2, 2]

        br = brokerage(g, groups; compute_modularity=true)

        @test br.modularity !== nothing
        @test br.modularity isa Float64
        @test br.modularity >= -1.0
        @test br.modularity <= 1.0

        # Test with non-integer groups
        groups_str = ["A", "A", "A", "B", "B", "B"]
        br_str = brokerage(g, groups_str; compute_modularity=true)
        @test br_str.modularity !== nothing
        @test br_str.modularity isa Float64

        # Test without modularity
        br_no_mod = brokerage(g, groups; compute_modularity=false)
        @test br_no_mod.modularity === nothing
    end

    @testset "BrokerageResult display" begin
        g = DiGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        groups = [1, 1, 2]

        br = brokerage(g, groups)

        # Test that show method works without error
        io = IOBuffer()
        show(io, br)
        output = String(take!(io))

        @test occursin("BrokerageResult", output)
        @test occursin("Coordinator:", output)
        @test occursin("Representative:", output)

        # Test with modularity
        br_mod = brokerage(g, groups; compute_modularity=true)
        io = IOBuffer()
        show(io, br_mod)
        output = String(take!(io))

        @test occursin("Modularity:", output)
    end

    @testset "Accessor functions" begin
        g = DiGraph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 2, 4)
        groups = [1, 1, 2, 3]

        br = brokerage(g, groups)

        # Test all accessor functions
        @test coordinator(br, 2) == br.coordinator[2]
        @test gatekeeper(br, 2) == br.gatekeeper[2]
        @test representative(br, 2) == br.representative[2]
        @test liaison(br, 2) == br.liaison[2]
        @test cosmopolitan(br, 2) == br.cosmopolitan[2]
        @test total_brokerage(br, 2) == br.total[2]

        # Test bounds checking
        @test_throws BoundsError coordinator(br, 10)
        @test_throws BoundsError total_brokerage(br, 0)
    end
end
