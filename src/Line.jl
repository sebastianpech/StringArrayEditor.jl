mutable struct Line <: Reference
    file::Union{File,Nothing}
    ln::Union{Int,Nothing}
    function Line(f::File,no::Int)
        @assert length(f.data) >= no
        @assert no > 0
        l = new(f,no)
        push!(f.references,l)
        return l
    end
end

==(a::Line,b::Line) = a.ln == b.ln && a.file === b.file

@alive l value(l::Line) = l.file.data[l.ln]

function show(io::IO,l::Line)
    if l.file == nothing
        print(io,"*Deleted*")
    else
        print(io,"Line($(l.ln)) #$(value(l)|> truncate)")
    end
end

@alive l next(l::Line,i::Int=1) = Line(l.file,l.ln+i)
@alive l prev(l::Line,i::Int=1) = Line(l.file,l.ln-i)

+(l::Line,i::Int) = next(l,i)
-(l::Line,i::Int) = prev(l,i)
+(i::Int,l::Line) = next(l,i)
-(i::Int,l::Line) = prev(l,i)

@alive l copy(l::Line) = Line(l.file,l.ln)

#=
Delete functions
=#
@alive l function delete!(l::Line)
    deletefromreferences!(l.file,l)
    deleteat!(l.file.data,l.ln)
    notify_delete(l.file,l)
    destroy!(l)
    return nothing
end

@alive l function destroy!(l::Line)
    l.file = nothing
    l.ln = nothing
end
isdestroyed(l::Line) = l.ln == nothing && l.file == nothing

function notify_delete(self::Line,del::Line)
    if self.ln > del.ln
        self.ln -= 1
    elseif self.ln == del.ln
        deletefromreferences!(self.file,self)
        destroy!(self)
    end
end

#=
Insert functions
=#

@alive l function insert!(l::Line,str::String)
    notify_insert(l.file,l,1)
    insert!(l.file.data,l.ln,str)
    l.ln += 1
    return nothing
end

@alive l function insert!(l::Line,str::Vector{String})
    notify_insert(l.file,l,length(str))
    splice!(l.file.data,l.ln:l.ln-1,str)
    l.ln += length(str)
    return nothing
end

@alive l from insert!(l::Line,from::T) where T<:Reference = insert!(l,value(from))

function notify_insert(self::Line,ins::Line,lines::Int)
    if self.ln >= ins.ln
        self.ln += lines
    end
end

#=
Append functions
=#

@alive l function append!(l::Line,str::String)
    notify_append(l.file,l,1)
    if l.ln < length(l.file.data)
        insert!(l.file.data,l.ln+1,str)
    else
        push!(l.file.data,str)
    end
    return nothing
end

@alive l function append!(l::Line,str::Vector{String})
    notify_append(l.file,l,length(str))
    if l.ln < length(l.file.data)
        splice!(l.file.data,l.ln+1:l.ln,str)
    else
        append!(l.file.data,str)
    end
    return nothing
end

@alive l from append!(l::Line,from::T) where T<:Reference = append!(l,value(from))

function notify_append(self::Line,app::Line,lines::Int)
    if self.ln > app.ln
        self.ln += lines
    end
end

#=
Replace functions
=#

@alive l function replace!(l::Line,str::String)
    l.file.data[l.ln] = str
    return l
end

@alive l from replace!(l::Line,from::T) where T<:Reference = replace!(l,value(from))

###############################################################################
#                                     Move                                    #
###############################################################################

movebeforeline(ref::Line) = ref.ln
moveafterline(ref::Line) = ref.ln

@alive self to function move(self::Line,to::T) where T<:Reference
    nfrom = movebeforeline(to)
    # Insert
    insert!(self,to)
    # Delete
    notify_delete(self.file,self)
    deleteat!(self.file.data,self.from:self.to)
    # Move Line pointer
    self.from = nfrom
end

@alive self to moveafter(self::Line,to::T) where T<:Reference = move(self,next(to))
