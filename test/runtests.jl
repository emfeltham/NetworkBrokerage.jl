using NetworkConstraint
using Test

@testset "NetworkConstraint.jl" begin
    include("test_constraint.jl")
    include("test_investment.jl")
    include("test_dyadconstraint.jl")
    include("test_directed.jl")
    include("test_directed_weighted.jl")
    include("test_mode_parameter.jl")
    include("test_selfloops.jl")
end
