module StringArrayEditor

export
    load,
    Line,
    insert!,
    delete!,
    append!,
    replace!,
    Range,
    value,
    save,
    map!,
    map,
    prev,
    next

import Base:show,delete!,insert!,copy,append!,==,length,iterate,getindex,in,replace!,findfirst,findnext,map!,next,map

using PrePostCall

"""
    Reference

Every new reference i.e. line or range must be a subtype of Reference

"""
abstract type Reference end

struct File 
    data::Vector{String}
    references::Vector{Reference}
    function File(data::Vector{T}) where T<: AbstractString
        new(data,Vector{Reference}())
    end
end

"""
    load(path::AbstractString)

Load the file from `path` into memory and return a File object.
"""
function load(path::AbstractString)
    return File(readlines(path))
end

function save(f::File,path::AbstractString)
    open(path,"w") do d
        for l in f.data
            write(d,l,"\n")
        end
    end
end

function show(io::IO,f::File)
    print(io,"File(<Lines $(length(f.data))>,<Ref $(length(f.references))>)")
end

function deletefromreferences!(f::File,del::Reference)
    for (idx,ref) in enumerate(f.references)
        if ref === del
            deleteat!(f.references,idx)
            return nothing
        end
    end
    error("Reference $del not found in $f")
end

function notify_delete(f::File,del::Reference)
    for ref in f.references|>copy
        ref === del && continue # Skip del
        notify_delete(ref,del)
    end
end
    
function notify_insert(f::File,ins::Reference,lines::Int)
    for ref in f.references
        ref === ins && continue # Skip ins
        notify_insert(ref,ins,lines)
    end
end
    
function notify_append(f::File,app::Reference,lines::Int)
    for ref in f.references
        ref === app && continue # Skip ins
        notify_append(ref,app,lines)
    end
end
    
function notify_replace(f::File,rep::Reference,lines::Int)
    for ref in f.references|>copy
        ref === rep && continue # Skip ins
        notify_replace(ref,rep,lines)
    end
end

include("./misc.jl")
include("./Line.jl")
include("./Range.jl")
include("./Collection.jl")
include("./Search.jl")

end
