function truncate(str::T,n::Int=30) where T<:AbstractString
    if length(str) > n
        return "$(str[1:n-3])..."
    end
    return str
end
