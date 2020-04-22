using Pkg

pkg"add HTTP"
pkg"add Gumbo"
pkg"add Cascadia"
pkg"add GitHub"

using HTTP
using Gumbo
using Cascadia
using GitHub

function get_latest_version_from_gmsh_web()
    webpage = "http://gmsh.info/"
    r = HTTP.request(:GET, webpage)
    r.status == 200 || error("Cannot access $(webpage).")

    h = parsehtml(String(r.body))
    s = Selector(".highlight")
    qs = eachmatch(s, h.root)
    version_div = qs[1].children[1].text
    return match(r"\d\.\d\.\d", qs[1].children[1].text).match |> VersionNumber
end

function get_latest_version_from_repo(repo_url)
    rels = try
         releases(GitHub.DEFAULT_API, repo(repo_url))[1]
    catch e
        if occursin("Not Found", e.msg)
            # didn't found the repo
            []
        else
            throw(e)
        end
    end
    isempty(rels) && return typemin(VersionNumber)
    match(r"\d\.\d\.\d", rels[1].tag_name).match |> VersionNumber
end

const url_jll = "shipengcheng1230/Gmsh_jll.jl"

v₁ = get_latest_version_from_gmsh_web()
v₂ = get_latest_version_from_repo(url_jll)

@info "Latest Gmsh SDK Version: $(v₁)"
@info "Current Gmsh_SDK_jll.jl Version: $(v₂)"

if abspath(PROGRAM_FILE) == @__FILE__
    if v₁ > v₂
        pkg"add BinaryBuilder"
        ENV["LATEST_GMSH_VERSION"] = v₁
        push!(ARGS, "--deploy=shipengcheng1230/Gmsh_jll.jl")
        include(joinpath(@__DIR__, "build_tarballs.jl"))
    end
end
