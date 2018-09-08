function findfirst(f::File,r::Regex;from::Int=1,to::Int=length(f.data))
    for l in from:to
        if occursin(r,f.data[l])
            return l
        end
    end
    return nothing
end

findnext(f::File,r::Regex,ln::Int) = findfirst(f,r,from=ln)

function finduntil(f::File,r::Regex;from::Int=1,to::Int=length(f.data))
    for l in from:to
        if !occursin(r,f.data[l])
            return l-1
        end
    end
    return to
end

parseSpecifier(f::File,s::Line,::Val{:after})= s.ln+1
parseSpecifier(f::File,s::Int,::Val{:after}) = s+1
parseSpecifier(f::File,s::Line,::Val{:before})= s.ln-1
parseSpecifier(f::File,s::Int,::Val{:before}) = s-1
parseSpecifier(f::File,s::Line,::Val{T}) where T= s.ln
parseSpecifier(f::File,s::Int,::Val{T}) where T= s
parseSpecifier(f::File,s::Nothing,::Val{:after}) = 1
parseSpecifier(f::File,s::Nothing,::Val{:before}) = length(f.data)

function Line(f::File,r::Regex;
              after::A=nothing,
              before::B=nothing
              ) where {A<:Union{Regex,Line,Int,Nothing}, B<:Union{Regex,Line,Int,Nothing}}
    if A == Regex
        _after = findfirst(f,after)
    else
        _after = parseSpecifier(f,after,Val{:after}())
    end

    _after == nothing && error("After ($after) was not found in the file")
    _after > length(f.data) && error("After is larger then the files length.")
    
    if B == Regex
        _before = findfirst(f,before,from=_after+1)
    else
        _before = parseSpecifier(f,before,Val{:before}())
    end
    
    _before == nothing && error("Before ($before) was not found in the file")
    _before > length(f.data) && error("Before is larger then the files length.")
    _after > _before && error("After must be smaller than before!")
    ind = findfirst(f,r,from=_after,to=_before)
    ind == nothing && error("$r was not found in the file")
    return Line(f,ind)
end

function Range(f::File;
               from::F=nothing,
               to::T=nothing,
               until::U=nothing,
               after::A=nothing,
               before::B=nothing) where {
                   F<:Union{Regex,Line,Int,Nothing},
                   T<:Union{Regex,Line,Int,Nothing},
                   U<:Union{Regex,Nothing},
                   A<:Union{Regex,Line,Int,Nothing},
                   B<:Union{Regex,Line,Int,Nothing}
               }
    (T != Nothing && U != Nothing) && error("A range cannot be specified by to AND until.")
    (T == Nothing && U == Nothing) && error("A range must be definied with to or until.")

    # after --> from ----> to ----> before
    # after --> from ---> until ---> before

    if A == Regex
        _after = findfirst(f,after)
    else
        _after = parseSpecifier(f,after,Val{:after}())
    end

    _after > length(f.data) && error("After is larger then the files length.")
    _after == nothing && error("After ($after) was not found in the file")
    
    if B == Regex
        _before = findfirst(f,before,from=_after+1)
    else
        _before = parseSpecifier(f,before,Val{:before}())
    end

    
    _before == nothing && error("Before ($before) was not found in the file")
    _before > length(f.data) && error("Before is larger then the files length.")
    _after > _before && error("After must be smaller than before!")

    if F == Regex
        _from = findfirst(f,from,from=_after,to=_before)
        _from == nothing && error("From ($from) was not found in the file")
    elseif from != nothing
        _from = parseSpecifier(f,from,Val{:from}())
    else
        _from = 1
    end
    
    _before < _from && error("From must be smaller than before!")

    if U == Regex
        _to = finduntil(f,until,from=max(_from,_after)+1,to=_before)
        _to == nothing && error("Until ($until) was not found in the file")
    elseif T == Regex
        _to = findfirst(f,to,from=max(_from,_after)+1,to=_before)
        _to == nothing && error("To ($to) was not found in the file")
    elseif isa(to,Int)
        _to = _from + to
    elseif to != nothing
        _to = parseSpecifier(f,from,Val{:to}())
    else
        _to = _before
    end
    
    _after > _to && error("To must be larger than after!")
    _before < _to && error("To must be smaller than before!")
    _from >= _to && error("To must be larger than from!")

    Range(f,_from,_to)
end
