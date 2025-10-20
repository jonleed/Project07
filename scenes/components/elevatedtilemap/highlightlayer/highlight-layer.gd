class_name HighlightLayer
extends Node2D

@export var terrain_tile_map: TerrainTileMap = null;
@export var highlight_object_packed: PackedScene = null;

func highlight_surface_cells(surface_cells: Array[Vector2i]):
    for surface_cell in surface_cells:
        var res = terrain_tile_map.surface_to_global(surface_cell);
        if res == null:
            continue;
        var highlight: Node2D = highlight_object_packed.instantiate()
        add_child(highlight);
        highlight.global_position = res;

func clear_highlights():
    for node in get_children():
        remove_child(node);
        node.queue_free();

func clear_then_highlight_surface_cells(surface_cells: Array[Vector2i]):
    clear_highlights();
    highlight_surface_cells(surface_cells);