using MethodInSrc
using Test

# Some incomprehensible failure with JET
# on Julia v 1.6
if VERSION >= v"1.7"
    include("jet_test.jl")
end
include("aqua_test.jl")
include("method_in_src.jl")
