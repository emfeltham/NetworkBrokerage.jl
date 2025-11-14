using NetworkBrokerage
using Test

@testset "NetworkBrokerage.jl" begin
    include("test_constraint.jl")
    include("test_investment.jl")
    include("test_dyadconstraint.jl")
    include("test_weighted_undirected.jl")
    include("test_directed.jl")
    include("test_directed_weighted.jl")
    include("test_mode_parameter.jl")
    include("test_selfloops.jl")
    include("test_negative_weights.jl")
    include("test_brokerage.jl")
    include("test_brokerage_integration.jl")
end
