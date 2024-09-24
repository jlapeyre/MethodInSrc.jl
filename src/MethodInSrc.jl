module MethodInSrc

"""
    module MethodInSrc

`MethodInSrc` provides tools to use in your test suite that verify that a function call
dispatches (or does not) to a method defined in your module.  They are meant to verify
that a specialized method is called rather than a more generic one. (Or vice versa.)

This module exports `@isinsrc`, `@insrc`, `@ninsrc`, `@isinmodule`, `@inmodule`, and
`@ninmodule`.

`@isinsrc f(x)` returns `true` if the method for `f(x)` is found under `../src`. But, it does not evaluate `f(x)`.

`@insrc f(x)` throws an error if the method for `f(x)` is not found under `../src`. Otherwise, it evaluates `f(x)`.

`@ninsrc` is the same as `@insrc` except that it throws if the method *is* under `../src`.

The first three macros are meant to be used in files in your module's "test" directory.
In this case, `@isinsrc f([x,...])` returns `true` if the method that would be called by
`f([x,...])` was defined in the module's "src" directory.

See the doc strings for `@isinmodule`, `@inmodule`, and  `@ninmodule`.

## Examples

Suppose the type `MyPackage.AMatrix` represents a square matrix whose elements are all
equal to `1`.  `MyPackage` extends `Base.sum` with an efficient method for `::AMatrix`.
`MyPackage` also includes an efficient function `prod(::AMatrix)`.  But, we neglected to
write `Base.prod` or `import Base: prod`.  So `MyPackage.prod` is not an extension of
`Base.prod`.


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

Use `@insrc` if you are too lazy to write two tests, one to verify that you have the
correct method, and another to test its correctness.

`@insrc` verifies that the methods are defined in "../src", and then evaluate the
expressions.  Below it is assumed we know that `MyPackage.prod` is a different function
and test for it.

These tests all pass.
```julia
using MyPackage
using MethodInSrc
using Test

N = 3
m = MyPackage.AMatrix{Int}(N)

# Note that `@insrc` takes the next expression as an argument.
# We need to test just the function call.
@test_throws ErrorException 1 == @insrc prod(m)   # This finds the method.
@test_throws ErrorException @insrc(prod(m)) == 1  # This does too.
@test 1 == @ninsrc prod(m)  # Do the test if the method is generic

# The following methods are found in "../src", so the expressions are evaluated
@test N^2 == @insrc sum(m)
@test (@insrc sum(m)) == N^2
@test @insrc(MyPackage.prod(m)) == 1
```
"""
MethodInSrc

using InteractiveUtils

export @isinsrc, @insrc, @ninsrc, @inmodule, @ninmodule, @isinmodule

"""
    findmethod(call::Expr)

Return the `Method` invoked by `call`.
"""
findmethod(call) = InteractiveUtils.gen_call_with_extracted_types(@__MODULE__, :which, call)

srcdir(testdir) = abspath(joinpath(testdir, "..", "src"))
srcdir() = srcdir(pwd())

"""
    methoddir(meth::Method)

Return the path to the directory containing the source for `meth`.
For methods in `Base`, return the empty string.
"""
methoddir(meth::Method) = dirname(string(meth.file))

methpath(meth::Method) = string(meth.file)

"""
    issubdir(dir::AbstractString, subdir::AbstractString)

Return `true` if `subdir` is a proper subdirectory of `dir`.
"""
function issubdir(dir::AbstractString, subdir::AbstractString)
    dirparts = splitpath(normpath(dir))
    subdirparts = splitpath(normpath(subdir))
    length(subdirparts) < length(dirparts) && return false
    subdirparts[1:length(dirparts)] == dirparts && return true
    return false
end

"""
    isdirorsubdir(dir::AbstractString, subdir::AbstractString)

Return `true` if `subdir` is equal to, or a subdirectory of, `dir`.
"""
function isdirorsubdir(dir::AbstractString, subdir::AbstractString)
    dir == subdir && return true
    return issubdir(dir, subdir)
end

"""
    @isinsrc f([x, y,...])

Return `true` if the method that would be called for the expression is in the source
directory ("src") of the module in which the test running. Otherwise, return `false`.

`@isinsrc` is meant to be called from within a module's "test" directory.  The src
directory is then found via "test/../src".

To test if a method is *not* in the source directory, use `@test ! @isinsrc f(x,...)`.

### Example
Verify that the method for `sum` is defined in `MyPackage`.
```julia
using MyPackage
using MethodInSrc
using Test

m = MyPackage.AMatrix(3)
@test @isinsrc sum(m)
```
"""
macro isinsrc(call)
    quote
        isdirorsubdir(srcdir(), methoddir($(findmethod(call))))
    end
end

"""
    @insrc f([x, y,...])

Evaluate the expression if the method called is defined in the source directory ("src") of
the module in which the test running. Otherwise, throw an `ErrorException`.

`@insrc` is meant to be called from within a module's "test" directory.  The src directory
is then found via "test/../src".

### Example
Verify that the method for `sum` is defined in `MyPackage`.
```julia
using MyPackage
using MethodInSrc
using Test

m = MyPackage.AMatrix(3)
@test @insrc(sum(m)) == 9
```
"""
macro insrc(call)
    meth = findmethod(call)
    quote
        src_dir = srcdir()
        methdir = methoddir($meth)
        if ! isdirorsubdir(src_dir, methdir)
            throw(ErrorException("@insrc: Method defined in '$(methpath($meth))', not in '$src_dir'."))
        end
        $(esc(call))
    end
end

"""
    @ninsrc f([x, y,...])

The same as `@insrc` except that `@ninsrc` throws an error if the method *is* in "../src",
while `@insrc` throws if the method is *not* in "../src".
"""
macro ninsrc(call)
    meth = findmethod(call)
    quote
        src_dir = srcdir()
        methdir = methoddir($meth)
        if isdirorsubdir(src_dir, methdir)
            throw(ErrorException("@ninsrc: Method defined in '$(methpath($meth))', which is a subdirectory of '$src_dir'."))
        end
        $(esc(call))
    end
end

"""
    @isinmodule ModuleName f([x, y,...])

Return `true` if the method that would be called for the expression is in the source
directory ("src") of `ModuleName`.
"""
macro isinmodule(mod, call)
    quote
        isdirorsubdir(dirname(pathof($(esc(mod)))), methoddir($(findmethod(call))))
    end
end

"""
    @inmodule ModuleName f([x, y,...])


Evaluate the the expressoin `f...` if the method called is defined in the source directory
of `ModuleName`. Otherwise throw an ErrorException.
"""
macro inmodule(mod, call)
    meth = findmethod(call)
    quote
        src_dir = dirname(pathof($(esc(mod))))
        methdir = methoddir($meth)
        if ! isdirorsubdir(src_dir, methdir)
            throw(ErrorException("@inmodule: Method defined in '$(methpath($meth))', not in '$src_dir'."))
        end
        $(esc(call))
    end
end

"""
    @ninmodule ModuleName f([x, y,...])


Evaluate the the expressoin `f...` if the method called is *not* defined in the source
directory of `ModuleName`. Otherwise throw an ErrorException.
"""
macro ninmodule(mod, call)
    meth = findmethod(call)
    quote
        src_dir = dirname(pathof($(esc(mod))))
        methdir = methoddir($meth)
        if isdirorsubdir(src_dir, methdir)
            throw(ErrorException("@ninmodule: Method defined in '$(methpath($meth))', which is a subdirectory of '$src_dir'."))
        end
        $(esc(call))
    end
end

# include code defining a type and methods for use in testing this module
include("testmethods.jl")
include("subdir/method_in_subdir.jl")

end # module
