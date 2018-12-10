using MethodInSrc
using Test

@testset "auxilliary" begin
    @test ! MethodInSrc.issubdir("/a/b/c/", "/a/g/c/d")
end

# MethodInSrc includes a type `AMatrix` just for testing.
# `sum(::AMatrix)` extends the function `Base.sum`
# `prod(::AMatrix)` is a new function defined in `MethodsInSrc`.
@testset "@isinsrc" begin
    N = 4
    m = MethodInSrc.AMatrix{Int}(N)

    @test @isinsrc sum(m)    # The extension to `Base.sum` is found in "../src/"
    @test sum(m) == N^2      # It gives the correct result.

    @test ! @isinsrc prod(m) # the generic method for `prod(::AbstractMethod)` is invoked.
    @test prod(m) == 1       # The generic method gives the correct result.
    @test @isinsrc MethodInSrc.prod(m) # This finds the function with one method defined in "../src/".
    @test MethodInSrc.prod(m) == 1     # The function in the module also gives the correct result.
end

@testset "@insrc" begin
    N = 3
    m = MethodInSrc.AMatrix{Int}(N)

    # Note that `@insrc` takes the next expression as an argument.
    # We need to test just the function call.
    @test_throws ErrorException 1 == @insrc prod(m)   # This finds the method.
    @test_throws ErrorException @insrc(prod(m)) == 1  # This does too.

    # The following methods are found in "../src", so the expressions are evaluated
    @test N^2 == @insrc sum(m)
    @test (@insrc sum(m)) == N^2
    @test @insrc(MethodInSrc.prod(m)) == 1
end

@testset "@ninsrc" begin
    N = 3
    m = MethodInSrc.AMatrix{Int}(N)
    @test 1 == @ninsrc prod(m)
end

@testset "methods in subdirectory of src" begin
    N = 4
    m = MethodInSrc.AMatrix{Int}(N)
    @test @isinsrc isone(m)
    @test ! @isinsrc iszero(m)
    @test  @isinsrc MethodInSrc.iszero(m)
    @test ! @insrc isone(m)
    @test ! @insrc MethodInSrc.iszero(m)
end
