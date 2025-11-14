using NetworkConstraint
using Test

@testset "NetworkConstraint.jl" begin
    include("test_constraint.jl")
    include("test_investment.jl")
    include("test_dyadconstraint.jl")
end
