mutable struct Range <: Reference
    file::Union{File,Nothing}
    from::Union{Int,Nothing}
    to::Union{Int,Nothing}
    function Range(f::File,from::Int,to::Int)
        @assert from < to
        @assert length(f.data) >= to
        r = new(f,from,to)
        push!(f.references,r)
        return r
    end
end

@post function resolveRange(r::Range)
    if !isdestroyed(r) && !((r.from < r.to))
        deletefromreferences!(r.file,r)
        destroy!(r)
    end
end

iterate(r::Range) = (r.from,r.from)

function iterate(r::Range,state::Int)
    if state < r.to
        return (state+1,state+1)
    else
        return nothing
    end
end

eltype(r::Range) = Int

@alive r value(r::Range) = r.file.data[r.from:r.to]
@alive r function value(r::Range,idx::Int)
    idx > length(r) && BoundsError(r,idx)
    return r.file.data[r.from+idx-1]
end

@alive r length(r::Range) = r.to-r.from+1

==(a::Range,b::Range) = a.from == b.from && a.to == b.to && a.file === b.file

function show(io::IO,r::Range)
    if r.file == nothing
        print(io,"*Deleted*")
    else
        print(io,"Range($(r.from):$(r.to)) #$(truncate(value(r,1),12))▿$(truncate(value(r,length(r)),12))")
    end
end

@alive r next(r::Range) = Line(r.file,r.to+1)
@alive r prev(r::Range) = Line(r.file,r.from-1)

@alive r copy(r::Range) = Range(r.file,r.from,r.to)

#=
Delete functions
=#
@alive r function delete!(r::Range)
    notify_delete(r.file,r)
    deletefromreferences!(r.file,r)
    deleteat!(r.file.data,r.from:r.to)
    destroy!(r)
    return nothing
end

@alive r function destroy!(r::Range)
    r.from = nothing
    r.to = nothing
    r.file = nothing
end

isdestroyed(r::Range) = r.from == nothing && r.to == nothing && r.file == nothing

@alive sub sup function in(sub::Range,sup::Range)
    sub.from >= sup.from && sub.to <= sup.to
end
@alive sub sup function in(sub::Line,sup::Range)
    sub.ln >= sup.from && sub.ln <= sup.to
end

@resolveRange self function notify_delete(self::Range,del::Range)
    del_len = length(del)
    if del.to < self.from 
        self.from -= del_len
        self.to -= del_len
    elseif del in self
        self.to -= del_len
    elseif !(del.from > self.to)
        deletefromreferences!(self.file,self)
        destroy!(self)
    end
end

@resolveRange self function notify_delete(self::Range,del::Line)
    del_len = 1
    if del.ln < self.from 
        self.from -= del_len
        self.to -= del_len
    elseif del in self
        self.to -= del_len
    elseif !(del.ln > self.to)
        deletefromreferences!(self.file,self)
        destroy!(self)
    end
end

function notify_delete(self::Line,del::Range)
    del_len = length(del)
    if self.ln > del.to
        self.ln -= del_len
    elseif self in del
        deletefromreferences!(self.file,self)
        destroy!(self)
    end
end

#=
Insert functions
=#

@alive r function insert!(r::Range,str::Vector{String})
    notify_insert(r.file,r,length(str))
    splice!(r.file.data,r.from:r.from-1,str)
    r.from += length(str)
    r.to += length(str)
    return nothing
end

@alive r insert!(r::Range,str::String) = insert!(r::Range,[str,])
@alive r from insert!(r::Range,from::T) where T<:Reference = insert!(r,value(from))

function notify_insert(self::Range,ins::Int,lines::Int)
    if self.from >= ins
        self.from += lines
    end
    if self.to >= ins
        self.to += lines
    end
end

notify_insert(self::Range,ins::Range,lines::Int) = notify_insert(self,ins.from,lines)
notify_insert(self::Range,ins::Line,lines::Int) = notify_insert(self,ins.ln,lines)

function notify_insert(self::Line,ins::Range,lines::Int)
    if self.ln >= ins.from
        self.ln += lines
    end
end

#=
Append functions
=#

@alive r function append!(r::Range,str::Vector{String})
    notify_append(r.file,r,length(str))
    splice!(r.file.data,r.to+1:r.to,str)
    return nothing
end

append!(r::Range,str::String) = append!(r::Range,[str,])
@alive r from append!(r::Range,from::T) where T<:Reference = append!(r,value(from))

notify_append(self::Range,ins::Range,lines::Int) = notify_insert(self,ins.from,lines)
notify_append(self::Range,ins::Line,lines::Int) = notify_insert(self,ins.ln,lines)

function notify_append(self::Line,ins::Range,lines::Int)
    if self.ln > ins.to
        self.ln += lines
    end
end

#=
Replace functions
=#

@alive r function replace!(r::Range,str::Vector{String})
    lines = length(r)-length(str)
    if lines == 0
        r.file.data[r.from:r.to] = str
    else
        splice!(r.file.data,r.from:r.to,str)
        notify_replace(r.file,r,lines)
    end
    if length(str) == 1
        ln = r.from
        file = r.file
        deletefromreferences!(file,r)
        destroy!(r)
        return Line(file,ln)
    end
    r.to = r.from + length(str)-1
    return r
end

@alive r replace!(r::Range,str::String) = replace!(r,[str,])

@alive l function replace!(l::Line,str::Vector{String})
    lines = 1-length(str)
    if lines == 0
        l.file.data[l.ln] = str[1]
    else
        splice!(l.file.data,l.ln,str)
        notify_replace(l.file,l,lines)
    end
    if length(str) > 1
        from = l.ln
        file = l.file
        deletefromreferences!(file,l)
        destroy!(l)
        return Range(file,from,from+length(str)-1)
    end
    return l
end

@resolveRange self function notify_replace(self::Range,rep::Range,lines::Int)
    if self.from >= rep.to
        self.from -= lines
        self.to -= lines
    elseif rep in self
        self.to -= lines
    elseif !(rep.from > self.to)
        deletefromreferences!(self.file,self)
        destroy!(self)
    end
end

@resolveRange self function notify_replace(self::Range,rep::Line,lines::Int)
    if rep.ln < self.from 
        self.from -= lines
        self.to -= lines
    elseif rep in self
        self.to -= lines
    elseif !(rep.ln > self.to)
        deletefromreferences!(self.file,self)
        destroy!(self)
    end
end

function notify_replace(self::Line,rep::Range,lines::Int)
    if self.ln > rep.to
        self.ln -= lines
    elseif self in rep
        deletefromreferences!(self.file,self)
        destroy!(self)
    end
end

function notify_replace(self::Line,rep::Line,lines::Int)
    if self.ln > rep.ln
        self.ln -= lines
    end
end

replace!(r::Range,from::T) where T<:Reference = replace!(r,value(from))

###############################################################################
#                                     Move                                    #
###############################################################################

movebeforeline(ref::Range) = ref.from
moveafterline(ref::Range) = ref.to

@alive self to function move(self::Range,to::T) where T<:Reference
    nfrom = movebeforeline(to)
    nto = nfrom + length(self)-1
    # Insert
    insert!(self,to)
    # Delete
    notify_delete(self.file,self)
    deleteat!(self.file.data,self.from:self.to)
    # Move Range pointer
    self.from = nfrom
    self.to = nto
end

@alive self to moveafter(self::Range,to::T) where T<:Reference = move(self,next(to))

###############################################################################
#                                Misc functions                               #
###############################################################################

@alive r function map!(fun::Function,r::Range)
    for i in r
        r.file.data[i] = fun(r.file.data[i])
    end
end

@alive r map(fun::Function,r::Range) = map(fun,r.file.data[r.from:r.to])
