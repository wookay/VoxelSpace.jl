module test_voxelspace_magicavoxel_parser

using Test
using VoxelSpace.MagicaVoxel
using .MagicaVoxel: Voxel, Model, Size, Material, VoxData
using .MagicaVoxel: DEFAULT_PALETTE, DEFAULT_MATERIALS
using .MagicaVoxel: parse_chunk, parse_material, parse_vox_file, chunk_to_data, placeholder
using Colors: RGBA

function resource(block, filename)
    path = normpath(@__DIR__, "resources", filename)
    f = open(path)
    block(f)
    close(f)
end

# https://github.com/davidedmonds/dot_vox/blob/master/src/parser.rs#L209

resource("valid_size.bytes") do f
    chunk = Size(24, 24, 24)
    @test parse_chunk(f) == (:SIZE, chunk)

    seekstart(f)
    @test chunk_to_data(chunk) == read(f)
end

resource("valid_voxels.bytes") do f
    chunk = [Voxel(0, 0, 0, 225), Voxel(0, 1, 1, 215), Voxel(1, 0, 1, 235), Voxel(1, 1, 0, 5)]
    @test parse_chunk(f) == (:XYZI, chunk)

    seekstart(f)
    @test chunk_to_data(chunk) == read(f)
end

resource("valid_palette.bytes") do f
    (chunk_id, chunk) = parse_chunk(f)
    @test chunk isa Vector{RGBA}
    @test length(chunk) == 256
    @test chunk[1] == RGBA(1, 1, 1, 1)
    @test chunk[end-1] == RGBA(17/255, 17/255, 17/255, 1)
    @test chunk[end] == RGBA(0, 0, 0, 0)

    seekstart(f)
    @test chunk_to_data(chunk) == read(f)
end

resource("valid_material.bytes") do f
    chunk = Material(0, (_type = "_diffuse", _weight = "1", _rough = "0.1", _spec = "0.5", _ior = "0.3"))
    @test parse_material(f) == chunk

    seekstart(f)
    @test chunk_to_data(chunk) == read(f)
end

resource("default_palette.bytes") do f
    chunk = MagicaVoxel.build_chunk(Val{:RGBA}(), f, 0, 0)
    @test first(chunk) == first(DEFAULT_PALETTE)
    @test MagicaVoxel.toRGBA(0xff99ccff) == RGBA(1, 0.8, 0.6, 1)
end

resource("placeholder.vox") do f
    chunk = parse_vox_file(f)
    @test chunk isa VoxData
    @test chunk.version == 150
    @test chunk.models[1].voxels == [Voxel(0, 0, 0, 225), Voxel(0, 1, 1, 215), Voxel(1, 0, 1, 235), Voxel(1, 1,0, 5)]
    @test first(chunk.palette) == first(DEFAULT_PALETTE)
    @test chunk.materials[1] == Material(0, (_type = "_diffuse", _weight = "1", _rough = "0.1", _spec = "0.5", _ior = "0.3"))
    @test chunk == placeholder(collect(DEFAULT_PALETTE), collect(DEFAULT_MATERIALS))
end

end # module test_voxelspace_magicavoxel_parser
