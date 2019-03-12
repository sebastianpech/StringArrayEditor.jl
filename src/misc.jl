function truncate(str::T,n::Int=30) where T<:AbstractString
    if length(str) > n
        return "$(str[1:n-3])..."
    end
    return str
end

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

"""
    peek(r<:Reference,n::Int=10)

Output n lines around r as string.

"""
function peek(l::Line,n::Int=10)
    lns = collect(max(l.ln-n,1):min(l.ln+n,length(l.file.data)))
    return peek(l.file,lns,[l.ln,])
end

function peek(r::Range,n::Int=10)
    from = max(r.from-n,1)
    to   = min(r.to+n,length(r.file.data))
    lns = vcat(collect(from:r.from+1),
               collect(r.to-1:to))
    return peek(r.file,lns,collect(r.from:r.to))
end

function peek(f::File,lns::Vector{Int},ln::Vector{Int})
    ln_str_length = length(string(lns[end]))
    ln_counter = 0
    str_with_ln = map(f.data[lns]) do _l
        ln_counter += 1
        if lns[ln_counter] in ln
            indicator = ">"
        else
            indicator = indicator_for_reference_at_ln(f,lns[ln_counter])
        end
        string(lpad(string(lns[ln_counter]),ln_str_length),"$indicator| ",_l)
    end
    println(join(str_with_ln,"\n"))
end

function indicator_for_reference_at_ln(f::File,ln::Int)
    for r in f.references
        if isa(r,Line) && r.ln == ln
            return "-"
        elseif isa(r,Range) && ln in r
            return "*"
        end
    end
    return " "
end
