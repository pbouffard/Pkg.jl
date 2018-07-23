# __precompile__(true)
module Pkg

import Random
import REPL
using REPL.TerminalMenus

depots() = Base.DEPOT_PATH
logdir() = joinpath(depots()[1], "logs")
devdir() = get(ENV, "JULIA_PKG_DEVDIR", joinpath(homedir(), ".julia", "dev"))
const UPDATED_REGISTRY_THIS_SESSION = Ref(false)

have_warned_session = false
function print_first_command_header()
    global have_warned_session
    have_warned_session && return
    isinteractive() || return
    if !PKG3_IS_PRECOMPILED && !haskey(ENV, "JULIA_PKG3_DISABLE_PRECOMPILE_WARNING")
        @info """
        Pkg is running without precompile statements, first action will be slow.
        Rebuild julia with the environment variable `JULIA_PKG3_PRECOMPILE` set to enable precompilation of Pkg.
        This message can be disabled by setting the env variable `JULIA_PKG3_DISABLE_PRECOMPILE_WARNING`.
        """
    end
    have_warned_session = true
end

# load snapshotted dependencies
include("../ext/TOML/src/TOML.jl")

include("GitTools.jl")
include("PlatformEngines.jl")
include("Types.jl")
include("Display.jl")
include("Pkg2/Pkg2.jl")
include("GraphType.jl")
include("Resolve.jl")
include("Operations.jl")
include("API.jl")
include("REPLMode.jl")

# Define new variables so tab comleting Pkg. works.
"""
    Pkg.add(package::String)
    Pkg.add(package::PackageSpec)

Adds a package to the current project. 
"""
const add          = API.add

const rm           = API.rm

"""
    Pkg.rm(package::String; )
    Pkg.rm(package::PackageSpec; )

"""
const up           = API.up
const test         = API.test
const gc           = API.gc
const build        = API.build
const installed    = API.installed
const pin          = API.pin
const free         = API.free
const checkout     = API.checkout
const develop      = API.develop
const generate     = API.generate
const instantiate  = API.instantiate
const resolve      = API.resolve
const status       = Display.status
const update       = up
const activate     = API.activate

"""
    PackageSpec(name::String, [uuid::UUID, version::VersionNumber])
    PacakgeSpec(; name, url, rev

A `PackageSpec` is a representation of how t
This includes:
    * The `name`
    * A `uuid`
    * A `version` range (for example when adding a package.
    * A path or alternatively a url and optional git revision

Most functions in Pkg take a `Vector` of `PackageSpec` and do the operation on all the packages
in the vector.

Below is a comparison between the REPL version and the `PackageSpec` version:



"""
const PackageSpec  = Types.PackageSpec

"""
    setprotocol!(proto::Union{Nothing, AbstractString}=nothing)

Set the protocol used to access GitHub-hosted packages when `add`ing a url or `develop`ing a package.
Defaults to 'https', with `proto == nothing` delegating the choice to the package developer.
"""
const setprotocol! = API.setprotocol!



# legacy CI script support
import .API: clone, dir

import .REPLMode: @pkg_str
export @pkg_str, PackageSpec


#function __init__()
    if isdefined(Base, :active_repl)
        REPLMode.repl_init(Base.active_repl)
    else
        atreplinit() do repl
            if isinteractive() && repl isa REPL.LineEditREPL
                isdefined(repl, :interface) || (repl.interface = REPL.setup_interface(repl))
                REPLMode.repl_init(repl)
            end
        end
    end
#end

module PrecompileArea
    using ..Types
    using UUIDs
    import LibGit2
    import Dates
    # This crashes low memory systems and some of Julia's CI
    # so keep it disabled by default for now.
    if haskey(ENV, "JULIA_PKG3_PRECOMPILE")
        const PKG3_IS_PRECOMPILED = true
        include("precompile.jl")
    else
        const PKG3_IS_PRECOMPILED = false
    end
end

METADATA_compatible_uuid(pkg::String) = Types.uuid5(Types.uuid_package, pkg)

end # module
