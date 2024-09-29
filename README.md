# MethodInSrc

[![Build Status](https://github.com/jlapeyre/MethodInSrc.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/MethodInSrc.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/MethodInSrc.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/MethodInSrc.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/main/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET QA](https://img.shields.io/badge/JET.jl-%E2%9C%88%EF%B8%8F-%23aa4444)](https://github.com/aviatesk/JET.jl)

`MethodInSrc` provides tools to use in your test suite that verify that
a function call dispatches (or does not) to a method defined in your module, or in another specified module.
They are meant to verify that a specialized method is called rather than a more generic one. (Or vice versa.)

## Motivation

Some code provides efficient, specialized methods for particular data types, rather than relying on fallack methods defined for more abstract types.
It's important that the input, the output, and the function call look exactly as they did before implementing the efficient method. So the test shouldn't change:
```julia
@test sum(A) = n
```
How then, apart from benchmarking, can you test that your new implementation is indeed called?
This module is a step towards a solution.

The problem becomes more complicated, and more error prone, if you have a file
defining binary operations, say multiplication, for combinations of various
particular and abstract types.  Are you sure dispatch is occurring as you intend?

Furthermore, due to changes in other code, someone may remove a specialized
method that has become redundant, or add a new one.  When reading this code
(even if you changed it yourself last year) and you can't find a method, did it
go missing, or was removed intentionally ?

_"... wait a minute, `foofunc` isn't in the source, but there's a test for it in the test suite--- and it's passing!"_

If you had written `@test @insrc(foofunc(A, b)) == c`, then the test would have failed as soon as `foofunc` was
removed from the source.

## Macros `@isinsrc`, `@insrc`, and `@ninsrc`

`@isinsrc f(x)` returns `true` if the method for `f(x)` is found under `../src`. But, it does not evaluate `f(x)`.

`@insrc f(x)` throws an error if the method for `f(x)` is not found under `../src`. Otherwise, it evaluates `f(x)`.

`@ninsrc` is the same as `@insrc` except that it throws if the method *is* under `../src`.

These three macros are meant to be used in files in your module's "test" directory.
In this case, `@isinsrc f([x,...])` returns `true` if the method that would be called by `f([x,...])` was defined
in the module's "src" directory.

## Macros `@isinmodule`, `@inmodule`, and `@ninmodule`

`@isinmodule ModuleName f(x)` returns `true` if the method for `f(x)` is found in the source directory
of `ModuleName`. But, it does not evaluate `f(x)`.

`@inmodule ModuleName f(x)` throws an error if the method for `f(x)` is not found under the source directory of `ModuleName`.
Otherwise, it evaluates `f(x)`.

`@ninmodule` is the same as `@inmodule` except that it throws if the method *is* under the source directory of `ModuleName`.

## Examples

Suppose the type `MyPackage.AMatrix` represents a square matrix whose elements are all equal to `1`.
`MyPackage` extends `Base.sum` with an efficient method for `::AMatrix`.
`MyPackage` also includes an efficient function `prod(::AMatrix)`.
But, we neglected to write `Base.prod` or `import Base: prod`.
So `MyPackage.prod` is not an extension of `Base.prod`.

### `@isinsrc`

Use `@isinsrc` to
check that both `sum` and `prod` extend `Base` functions. (`prod` does not!)
```julia
using MyPackage
using MethodInSrc
using Test

m = MyPackage.AMatrix{Int}(3)
@test @isinsrc sum(m)
@test @isinsrc prod(m)  # This will fail!
```

### `@insrc`, `@ninsrc`

Use `@insrc` if you are too lazy to write two tests,
one to verify that you have the correct method,
and another to test its correctness.

The following example assumes we know that `MyPackage.prod`
and `Base.prod` are different functions.
These tests all pass.
```julia
using MyPackage
using MethodInSrc
using Test

N = 3
m = MyPackage.AMatrix{Int}(N)

# Note that `@insrc` takes the next expression as an argument.
# So, `@insrc prod(m) == 1` will fail to locate the source for `prod`
@test_throws ErrorException 1 == @insrc prod(m)   # This finds the source for the method.
@test_throws ErrorException @insrc(prod(m)) == 1  # This does too.
@test 1 == @ninsrc prod(m)  # Do the test if the method *is* generic

# The following methods are found in "../src", so the expressions are evaluated
@test N^2 == @insrc sum(m)
@test (@insrc sum(m)) == N^2
@test @insrc(MyPackage.prod(m)) == 1
```

## Package using `MethodInSrc`

Following is obsolete

[`IdentityMatrix.jl`](https://github.com/jlapeyre/IdentityMatrix.jl) uses `MethodInSrc`
in [runtests.jl](https://github.com/jlapeyre/IdentityMatrix.jl/blob/main/test/runtests.jl).

`IdentityMatrix` (a misnomer) includes methods for types from `Base`, `LinearAlgebra`
and [`FillArrays`](https://github.com/JuliaArrays/FillArrays.jl). It serves as a way station for
some efficient methods. Methods have been moved from `IdentityMatrix` to `LinearAlgebra` and `FillArrays`.
These are methods for `one`, `sum`, `inv`, etc.
Keeping track of where I want the methods to be, and ensuring that they are indeed there, was as
good as impossible without something like `MethodInSrc`.

## Other examples

The [test suite for MethodInSrc](./test/runtests.jl) has more detailed examples
based on a toy type implemented in [./src/testmethods.jl](./src/testmethods.jl) 
and  [./src/subdir/method_in_subdir.jl](./src/subdir/method_in_subdir.jl)

<!--  LocalWords:  MethodInSrc Codecov splitpath src MyPackage AMatrix julia jl
 -->
<!--  LocalWords:  isinsrc ErrorException insrc ninsrc benchmarking ModuleName
 -->
<!--  LocalWords:  IdentityMatrix runtests LinearAlgebra FillArrays
 -->
