# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Gmsh_SDK"

include(joinpath(@__DIR__, "check_version.jl"))
version = get(ENV, "LATEST_GMSH_VERSION", nothing)
version === nothing && (version = v₂)

if version ≤ v₃
    @info "Latest build version detected $(version), abort building."
    exit(0)
end

# Collection of sources required to complete build

sources = [
    ArchiveSource("http://gmsh.info/src/gmsh-$(version)-source.tgz", "46eaeb0cdee5822fdaa4b15f92d8d160a8cc90c4565593cfa705de90df2a463f")
]

# Bash recipe for building across all platforms
script = "export gmsh_version=$(version)\n" * raw"""
cd $WORKSPACE/srcdir

if [[ "${target}" == *-mingw* ]]; then
    wget http://gmsh.info/bin/Windows/gmsh-${gmsh_version}-Windows${nbits}-sdk.zip
    unzip gmsh*sdk.zip
    mv ${libdir}/gmsh*.${dlext} ${libdir}/libgmsh.${dlext}
    cp -L gmsh*sdk/lib/* gmsh*sdk/bin
    cp -r -L gmsh*sdk/* ${prefix}
fi

if [[ "${target}" == *apple* ]]; then
    wget http://gmsh.info/bin/MacOSX/gmsh-${gmsh_version}-MacOSX-sdk.tgz
elif [[ "${target}" == *linux* ]]; then
    wget http://gmsh.info/bin/Linux/gmsh-${gmsh_version}-Linux${nbits}-sdk.tgz
fi

if [[ "${target}" == *apple* ]] || [[ "${target}" == *linux* ]]; then
    tar zxf gmsh*.tgz
    find gmsh*sdk/lib -type l -delete
    cp -r -L gmsh*sdk/* ${prefix}
fi

install_license ${WORKSPACE}/srcdir/gmsh*source/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    # Linux(:i686, libc=:glibc),
    Windows(:x86_64),
    # Windows(:i686),
    MacOS(:x86_64),
]

# platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgmsh", :libgmsh),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    # Dependency(PackageSpec(name="Xorg_libXcursor_jll", uuid="935fb764-8cf2-53bf-bb30-45bb1f8bf724"))
    # Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"))
    # Dependency(PackageSpec(name="Xorg_libXrender_jll", uuid="ea2f1a96-1ddc-540d-b46f-429655e07cfa"))
    # Dependency(PackageSpec(name="Xorg_libXext_jll", uuid="1082639a-0dae-5f34-9b06-72781eeb8cb3"))
    # Dependency(PackageSpec(name="Xorg_libXft_jll", uuid="2c808117-e144-5220-80d1-69d4eaa9352c"))
    # Dependency(PackageSpec(name="Xorg_libXfixes_jll", uuid="d091e8ba-531a-589c-9de9-94069b037ed8"))
    # Dependency(PackageSpec(name="Xorg_libXinerama_jll", uuid="d1454406-59df-5ea1-beac-c340f2130bc3"))
    # Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
    # Dependency(PackageSpec(name="Fontconfig_jll", uuid="a3f928ae-7b40-5064-980b-68af3947d34b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
