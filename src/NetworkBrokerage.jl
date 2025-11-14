module NetworkBrokerage

using Graphs, SimpleWeightedGraphs

include("helpers.jl")
include("weighted.jl")
include("investment.jl")
export investment

include("constraint.jl")
export dyadconstraint, constraint

# Brokerage functionality
include("brokerage_types.jl")
include("brokerage_helpers.jl")
include("brokerage.jl")
export brokerage, BrokerageResult
export coordinator, gatekeeper, representative, liaison, cosmopolitan, total_brokerage

end # module NetworkBrokerage
