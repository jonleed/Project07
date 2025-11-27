extends TileMapLayer

@onready var unit_display_packed:PackedScene = preload("res://scenes/components/phase1/unitdisplay/UnitDisplay.tscn")
@export var unit_resources:Array[UnitResource]
