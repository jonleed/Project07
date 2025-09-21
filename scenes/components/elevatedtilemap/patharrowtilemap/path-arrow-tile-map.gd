@tool
class_name PathArrowTileMap
extends ElevatedTileMap

@export var path_arrow_tile_info := TerrainInfo.new(0, 0, true, Enums.TerrainType.CONNECT);

func draw_path_arrow(path_arrow: Array[Vector3i]):
    draw_voxels([VoxelInfo.from_defined_terrain(path_arrow, path_arrow_tile_info)]);

func clear_path_arrow():
    for tile_map_layer: CustomTileMapLayer in get_children():
        tile_map_layer.clear();