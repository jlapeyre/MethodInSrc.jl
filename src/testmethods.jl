"""
    AMatrix{T} <: AbstractMatrix{T}

This type is for testing `@isinsrc` and `@insrc`. We implement
enough of the `AbstractMatrix` interface to test these macros.
"""
struct AMatrix{T} <: AbstractMatrix{T}
    n::Int
end

# ::AMatrix is square with sides of length `n`
Base.size(a::AMatrix) = (a.n, a.n)

# elements of ::AMatrix are all equal to 1
function Base.getindex(a::AMatrix{T}, i, j) where {T}
    @boundscheck checkbounds(a, i, j)
    return one(T)
end

# Convert to an allocated `Matrix`
Base.Matrix(a::AMatrix{T}) where {T} = ones(T, a.n, a.n)
Base.Array(a::AMatrix) = Matrix(a)

# We implement an efficient method for computing the sum of the elements.
Base.sum(a::AMatrix{T}) where T = T(a.n^2)

# We implement an efficient method for computing the product of the elements.
# BUT WE FORGET TO PREPEND `Base.`. So this method doe not extend the function in
# `Base` and is not visible unless qualified with the package name.
prod(a::AMatrix{T}) where T = one(T)
