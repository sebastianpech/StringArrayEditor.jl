mutable struct Collection <: Reference
    refs::Vector{Reference}
end

==(a::Collection,b::Collection) = a.refs == b.refs

@alive c value(c::Collection) = value.(c.refs) 

@alive c function destroy!(c::Collection)
    destroy!.(c.refs)
    c.refs = Vector{Reference}()
end
isdestroyed(c::Collection) = length(c.refs) == 0

function show(io::IO,c::Collection)
    if isdestroyed(c)
        print(io,"*Deleted*")
    else
        print(io,"$(length(c.refs))-element Collection:")
        for l in c.refs
            print(io,"\n $l")
        end
    end
end

iterate(c::Collection) = (c[1],1)

function iterate(c::Collection,state::Int)
    if state < length(c)
        return (c[state+1],state+1)
    else
        return nothing
    end
end

getindex(c::Collection,i::Int) = c.refs[i]

length(c::Collection) = length(c.refs)
    

@alive c next(c::Collection,i::Int=1) = next.(c.refs,i)
@alive c prev(c::Collection,i::Int=1) = prev.(c.refs,i)

+(c::Collection,i::Int) = next(c,i)
-(c::Collection,i::Int) = prev(c,i)
+(i::Int,c::Collection) = next(c,i)
-(i::Int,c::Collection) = prev(c,i)

@alive c copy(c::Collection) = Collection(copy(c.refs))

@alive c delete!(c::Collection) = delete!.(c.refs)
notify_delete(c::Collection,del::T) where T<:Reference = notify_delete.(c.refs,Ref{T}(del))

@alive c from insert!(c::Collection,from::T) where T<:Reference = insert!.(c.refs,Ref{T}(from)) |> Collection
@alive c insert!(c::Collection,from::T) where T<:Union{String,Vector{String}} = insert!.(c.refs,Ref{T}(from)) |> Collection
notify_insert(self::Collection,ins::T,lines::Int) where T<:Reference = notify_insert.(self.refs,Ref{T}(ins),Ref{T}(lines))

@alive c from append!(c::Collection,from::T) where T<:Reference = append!.(c.refs,from) |> Collection
@alive c append!(c::Collection,from::T) where T<:Union{String,Vector{String}} = append!.(c.refs,Ref{T}(from)) |> Collection
notify_append(self::Collection,app::T,lines::Int) where T<:Reference = notify_append.(self.refs,Ref{T}(app),lines)

@alive c from replace!(c::Collection,from::T) where T<:Reference = replace!.(c.refs,from) |> Collection
@alive c replace!(c::Collection,from::T) where T<:Union{String,Vector{String}} = replace!.(c.refs,Ref{T}(from)) |> Collection
notify_replace(self::Collection,rep::T,lines::Int) where T<:Reference = notify_replace.(self.refs,Ref{T}(rep),lines)

@alive self to function move!(self::Collection,to::Collection)
    length(self.refs) != length(to.refs) && error("Collection can only be moved to other collections with equal length.")
    for i in 1:length(self.refs)
        move!(self.refs[i],to.refs[i])
    end
end

@alive self to function moveafter!(self::Collection,to::Collection)
    length(self.refs) != length(to.refs) && error("Collection can only be moved to other collections with equal length.")
    for i in 1:length(self.refs)
        moveafter!(self.refs[i],to.refs[i])
    end
end


