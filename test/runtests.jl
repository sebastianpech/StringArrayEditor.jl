using Test
using StringArrayEditor

@testset "StringArrayEditor" begin
    f = load("./data/testfile01.txt")
    @testset "Loading" begin
        @test length(f.data) == 9
    end
    l1 = Line(f,3)
    l2 = Line(f,5)
    @testset "Reference Lines" begin
        @test l1.ln == 3
        @test l1.file == f
        @test_throws AssertionError Line(f,11)
        @test_throws AssertionError Line(f,0)
        @test length(f.references) == 2
        StringArrayEditor.value(l1) == "Line 3"
        StringArrayEditor.value(l2) == "Line 5"
    end
    same = copy(l1)
    @testset "Copy lines" begin
        @test l1.ln == same.ln
        @test l1.file === same.file
        @test !(l1 === same)
    end
    before = Line(f,1)
    @testset "Delete Lines" begin
        delete!(l1)
        @test l1.file == nothing
        @test l1.ln == nothing
        @test StringArrayEditor.value(l2) == "Line 5"
        @test l2.ln == 4
        @test before.ln == 1
        @test StringArrayEditor.value(before) == "Line 1"
        @test same.file == nothing
        @test same.ln == nothing
        @test length(f.references) == 2
        @test length(f.data) == 8
    end
    after = Line(f,7)
    @testset "Insert Lines" begin
        li = insert!(l2,"Hello World")
        @test isa(li,Line)
        @test value(li) == "Hello World"
        @test l2.ln == 5
        @test f.data[l2.ln-1] == "Hello World"
        @test after.ln == 8
        @test StringArrayEditor.value(after) == "Line 7"
        insert!(l2,after)
        @test f.data[l2.ln-1] == "Line 7"
        ri = insert!(l2,["Vec 1","Vec 2", "Vec 3"])
        @test isa(ri,Range)
        @test value(ri) == ["Vec 1","Vec 2","Vec 3"]
        @test l2.ln == 9
        @test f.data[l2.ln-4:l2.ln-1] == ["Line 7", "Vec 1","Vec 2", "Vec 3"]
        @test after.ln == 12
    end
    f = load("./data/testfile01.txt")
    l1 = Line(f,2)
    l2 = Line(f,3)
    l3 = Line(f,7)
    lend = Line(f,length(f.data))
    @testset "Append Lines" begin
        a1 = append!(l2,"Hello World")
        @test value(a1) == "Hello World"
        @test a1.ln == 4
        @test l2.ln == 3
        @test StringArrayEditor.value(l2) == "Line 3"
        @test l1.ln == 2
        @test StringArrayEditor.value(l1) == "Line 2"
        @test l3.ln == 8
        @test StringArrayEditor.value(l3) == "Line 3"
        append!(lend,"asdf")
        @test f.data[end-1:end] == ["Line 8", "asdf"]
        nlend = Line(f,length(f.data))
        a2 = append!(nlend,["ffff","gggg"])
        @test value(a2) == ["ffff","gggg"]
        @test a2.from == nlend.ln+1
        @test f.data[end-3:end] == ["Line 8", "asdf", "ffff", "gggg"]
        append!(l2,["ffff","gggg"])
        @test l3.ln == 10
        @test StringArrayEditor.value(l3) == "Line 3"
        @test l2.ln == 3
        @test StringArrayEditor.value(l2) == "Line 3"
        @test f.data[l2.ln:l2.ln+2] == ["Line 3", "ffff", "gggg"]
    end
    @testset "Range Creation" begin
        f = load("./data/testfile01.txt")
        r1 = Range(f,2,5)
        @test r1.from == 2
        @test r1.to == 5
        @test_throws AssertionError Range(f,3,2)
        @test_throws AssertionError Range(f,2,100)
        @test length(r1) == 4
        @test collect(r1) == [2,3,4,5]
        @test length(f.references) == 1
        @test value(r1) == ["Line 2","Line 3","Line 4", "Line 5"]
        @test !(r1 === copy(r1))
    end
    @testset "Delete Range" begin
        f = load("./data/testfile01.txt")
        lbefore = Line(f,2)
        lafter = Line(f,8)
        rbefore = Range(f,1,2)
        rafter = Range(f,8,9)
        rdel = Range(f,3,6)
        lin1 = Line(f,4)
        lin2 = Line(f,6)
        rin = Range(f,4,5)
        roverlap = Range(f,5,7)
        rsurround = Range(f,2,9)
        @test length(f.references) == 10
        delete!(rdel)
        @test length(f.references) == 5
        @test lbefore.ln == 2
        @test length(rbefore) == 2
        @test rbefore.from == 1
        @test rbefore.to == 2
        @test lafter.ln == 4
        @test length(rafter) == 2
        @test rafter.from == 4
        @test rafter.to == 5
        @test length(rsurround) == 4
        @test rsurround.from == 2
        @test rsurround.to == 5
        @test StringArrayEditor.isdestroyed(roverlap)
        @test StringArrayEditor.isdestroyed(lin1)
        @test StringArrayEditor.isdestroyed(lin2)
        @test StringArrayEditor.isdestroyed(rdel)
        @test StringArrayEditor.isdestroyed(rin)
        @test f.data == [ "Line 1",
                          "Line 2",
                          "Line 3",
                          "Line 7",
                          "Line 8"]
        delete!(lafter)
        @test f.data == [ "Line 1",
                          "Line 2",
                          "Line 3",
                          "Line 8"]
        @test lbefore.ln == 2
        @test rbefore.from == 1
        @test rbefore.to == 2
        @test StringArrayEditor.isdestroyed(lafter)
        @test length(rsurround) == 3
        @test length(f.references) == 4
    end
    @testset "Insert Range" begin
        f = load("./data/testfile01.txt")
        lbefore = Line(f,2)
        lafter = Line(f,8)
        rbefore = Range(f,1,2)
        rafter = Range(f,8,9)
        rins = Range(f,3,6)
        lin1 = Line(f,4)
        lin2 = Line(f,6)
        rin = Range(f,4,5)
        roverlap = Range(f,5,7)
        rsurround = Range(f,2,9)
        i2 = insert!(rbefore,"asdf")
        @test value(i2) == "asdf"
        @test i2.ln == rbefore.from-1
        @test lafter.ln == 9
        @test rafter.from == 9
        i3 = insert!(rin,["asdf","ffff"])
        @test value(i3) == ["asdf","ffff"]
        @test rin.from == 7
        @test rin.to == 8
        @test rsurround.from == 3
        @test rsurround.to == 12
        @test lin2.ln == 9
        insert!(lin1,"fff")
        @test rafter.from == 12
        insert!(lin1,rbefore)
        @test f.data[8] == "Line 1"
        @test f.data[9] == "Line 2"
        insert!(lin1,lin1)
        @test f.data[10] == "Line 4"
    end
@testset "Append Range" begin
    f = load("./data/testfile01.txt")
    lbefore = Line(f,2)
    lafter = Line(f,8)
    rbefore = Range(f,1,2)
    rafter = Range(f,8,9)
    rins = Range(f,3,6)
    lin1 = Line(f,4)
    lin2 = Line(f,6)
    rin = Range(f,4,5)
    roverlap = Range(f,5,7)
    rsurround = Range(f,2,9)
    ra = append!(rbefore,"asdf")
    @test value(ra) == "asdf"
    @test rbefore.from == 1
    @test rbefore.to == 2
    @test lafter.ln == 9
    @test rafter.from == 9
    ra2 = append!(rin,["asdf","ffff"])
    @test value(ra2) == ["asdf","ffff"]
    @test rin.from == 5
    @test rin.to == 6
    @test rsurround.from == 3
    @test rsurround.to == 12
    @test lin2.ln == 9
    append!(lin1,"fff")
    @test rafter.from == 12
    lin1
    append!(lin1,rbefore)
    @test f.data[6] == "Line 1"
    @test f.data[7] == "Line 2"
    append!(lin1,lin1)
    @test f.data[6] == "Line 4"
end
@testset "Replace" begin

    f = load("./data/testfile01.txt")
    lbefore = Line(f,2)
    lafter = Line(f,8)
    rbefore = Range(f,1,2)
    rafter = Range(f,8,9)
    rins = Range(f,3,6)
    lin1 = Line(f,4)
    lin2 = Line(f,6)
    rin = Range(f,4,5)
    roverlap = Range(f,5,7)
    rsurround = Range(f,2,9)
    replace!(lbefore,"ASDF")
    @test value(lbefore) == "ASDF"

    rnew = replace!(lbefore,["GGG","AAA"])
    @test f.data[2:3] == ["GGG","AAA"]
    @test lafter.ln == 9
    @test rbefore.from == 1
    @test rbefore.to == 3
    @test rafter.from == 9
    @test rafter.to == 10
    @test rins.from == 4
    @test rins.to == 7
    @test lin1.ln == 5
    @test lin2.ln == 7
    @test f.data[rsurround.from] == "GGG"

    f = load("./data/testfile01.txt")
    lbefore = Line(f,2)
    lafter = Line(f,8)
    rbefore = Range(f,1,2)
    rafter = Range(f,8,9)
    rins = Range(f,3,6)
    lin1 = Line(f,3)
    lin2 = Line(f,6)
    rin = Range(f,4,5)
    roverlap = Range(f,5,7)
    rsurround = Range(f,2,9)
    f.data
    replace!(lbefore,"ASDF")
    length(f.references)
    lnew = replace!(rins,"GGG")
    @test lnew.ln == 3
    @test StringArrayEditor.isdestroyed(lin1)
    @test StringArrayEditor.isdestroyed(lin2)
    @test StringArrayEditor.isdestroyed(roverlap)
    @test StringArrayEditor.isdestroyed(rin)
    @test lafter.ln == 8-3
    @test rsurround.to == 9-3
    @test rsurround.from == 2
    @test length(f.references) == 6
    @test f.data == [
        "Line 1",
        "ASDF"  ,
        "GGG"   ,
        "Line 3",
        "Line 7",
        "Line 8"
    ]
    l = replace!(lbefore,lafter)
    @test value(l) == "Line 7"
    l = replace!(lbefore,rafter)
    @test StringArrayEditor.isdestroyed(lbefore)
    @test value(l) == ["Line 7","Line 8"]
end

@testset "Search Functions" begin

    f = load("./data/testfile01.txt")
    l = Line(f,r"Line 2")
    @test l.ln == 2
    l2 = Line(f,r"Line 2",after=r"Line 5")
    @test l2.ln == 6
    l3 = Line(f,r"Line 2",after=l)
    @test l3.ln == 6
    @test_throws ErrorException Line(f,r"Line 7",before=l2)
    r = Range(f,from=r"Line 2",to=r"Line 2")
    @test r.from == 2
    @test r.to == 6
    r = Range(f,after=l,to=r"Line 3")
    @test r.from == 1
    @test r.to == 7
    r = Range(f,from=l,after=l,to=r"Line 3")
    @test r.from == 2
    @test r.to == 7
    replace!(l3,"ASDF")
    r = Range(f,from=l,until=r"Line")
    @test r.from == 2
    @test r.to == 5
end

@testset "Save" begin
    f = load("./data/testfile01.txt")
    save(f,"test.txt")
    @test readlines("test.txt") == f.data
    rm("test.txt")
end
@testset "Line and Range manipulations" begin
    f = load("./data/testfile01.txt")
    l1 = Line(f,1)
    l2 = l1+3
    @test l2.ln == 4
    l3 = l2-1
    @test l3.ln == 3
    r1 = Range(f,2,5)
    l2 = r1-1
    @test l2.ln == 1
    l3 = r1+2
    @test l3.ln == 7
    r2 = r1[2:end-1]
    @test r2.from == 3
    @test r2.to == 4
    @test_throws BoundsError r2[-1:end]
    @test_throws BoundsError r2[0:end]
    @test_throws BoundsError r2[1:20]
end
@testset "Move" begin
    f = load("./data/testfile01.txt")
    l = Line(f,1)
    r = replace!(l,["foo","bar","baz"])
    l = replace!(Line(f,8),"ASDF")
    move!(r,l)
    @test l.ln == 8
    f.data[l.ln-3:l.ln-1] == ["foo","bar","baz"]
    @test r.from == l.ln-3
    @test r.to == l.ln-1
    @test value(r) == ["foo","bar","baz"]
    move!(l,r)
    @test l.ln == 5
    @test value(l) == "ASDF"

end
end
