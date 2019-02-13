"""
    Line(f::File,no::Int)

Create a reference to line `no` in file `f`.
"""
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

"""
    next(l::Line,i::Int=1)

Returns the `i`-th line after `l`.
"""
@alive l next(l::Line,i::Int=1) = Line(l.file,l.ln+i)
"""
    prev(l::Line,i::Int=1)

Returns the `i`-th line before `l`.
"""
@alive l prev(l::Line,i::Int=1) = Line(l.file,l.ln-i)

+(l::Line,i::Int) = next(l,i)
-(l::Line,i::Int) = prev(l,i)
+(i::Int,l::Line) = next(l,i)
-(i::Int,l::Line) = prev(l,i)

"""
    copy(l::Line)

Create a copy of line `l`.
"""
@alive l copy(l::Line) = Line(l.file,l.ln)

#=
Delete functions
=#
"""
    delete!(l::Line)

Delete line `l` from the document it's in.
"""
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
"""
    insert!(l::Line,str::String)

Insert `str` before line `l`.
"""
@alive l function insert!(l::Line,str::String)
    notify_insert(l.file,l,1)
    insert!(l.file.data,l.ln,str)
    l.ln += 1
    return Line(l.file,l.ln-1)
end


"""
    insert!(l::Line,from::Reference)

Insert the value of reference `from` before line `l`.
"""
@alive l from insert!(l::Line,from::T) where T<:Reference = insert!(l,value(from))

function notify_insert(self::Line,ins::Line,lines::Int)
    if self.ln >= ins.ln
        self.ln += lines
    end
end

#=
Append functions
=#

"""
    append!(l::Line,str::String)

Append `str` after line `l`.
"""
@alive l function append!(l::Line,str::String)
    notify_append(l.file,l,1)
    if l.ln < length(l.file.data)
        insert!(l.file.data,l.ln+1,str)
    else
        push!(l.file.data,str)
    end
    return Line(l.file,l.ln+1)
end

"""
    append!(l::Line,from::Reference)

Append the value of reference `from` after line `l`.
"""
@alive l from append!(l::Line,from::T) where T<:Reference = append!(l,value(from))

function notify_append(self::Line,app::Line,lines::Int)
    if self.ln > app.ln
        self.ln += lines
    end
end

#=
Replace functions
=#

"""
    replace!(l::Line,str::String)

Replace the value of line `l` with `str`
"""
@alive l function replace!(l::Line,str::String)
    l.file.data[l.ln] = str
    return l
end

"""
    replace!(l::Line,from::Reference)

Replace line `l` with the value of `from`
"""
@alive l from replace!(l::Line,from::T) where T<:Reference = replace!(l,value(from))

function notify_replace(self::Line,rep::Line,lines::Int)
    if self.ln > rep.ln
        self.ln -= lines
    end
end

###############################################################################
#                                     Move                                    #
###############################################################################

movebeforeline(ref::Line) = ref.ln
moveafterline(ref::Line) = ref.ln

"""
    move!(self::Line,to::T)

Move `self` to `to`. This is a combination of `insert!(to,self)` and `delete!(self)`.
"""
@alive self to function move!(self::Line,to::T) where T<:Reference
    # Insert duplicate
    dup = insert!(to,self)
    # Delete original but keep reference
    notify_delete(self.file,self)
    deleteat!(self.file.data,self.ln)
    # Move pointer
    self.ln = dup.ln
    # Delete reference for dup
    deletefromreferences!(dup.file,dup)
    return self
end

"""
    moveafter!(self::Line,to::T)

Move `self` to the position after `to`. This is a combination of `append!(to,self)` and `delete!(self)`.
"""
@alive self to function moveafter!(self::Line,to::T) where T<:Reference
    # Insert duplicate
    dup = append!(to,self)
    # Delete original but keep reference
    notify_delete(self.file,self)
    deleteat!(self.file.data,self.ln)
    # Move pointer
    self.ln = dup.ln
    # Delete reference for dup
    deletefromreferences!(dup.file,dup)
    return self
end

