function truncate(str::T,n::Int=30) where T<:AbstractString
    if length(str) > n
        return "$(str[1:n-3])..."
    end
    return str
end

@pre alive(self::T) where T<:Reference = isdestroyed(self) && error("Can't perform operation on deleted $T.")

"""
    edit(f::File)

Save `f` to a temporary file and open with `edit`.
"""
function edit(f::File)
    # Save file to tmp
    path,io = mktemp()
    for l in f.data
        write(io,l,"\n")
    end
    close(io)
    # Edit File
    edit(path)
    rm(path)
end

"""
    edit(r<:Reference)

Save `r` to a temporary file and open with `edit`.
"""
function edit(r::T) where T<:Reference
    # Save file to tmp
    path,io = mktemp()
    writeToFile(io,value(r))
    close(io)
    # Edit File
    edit(path)
    # Reload edited stuff
    _edit = readlines(path)
    # Replace old with new
    replace!(r,_edit)
    rm(path)
end
