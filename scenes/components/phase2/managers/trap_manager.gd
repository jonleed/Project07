class_name Trap_Manager
extends Node

@export var map_manager: MapManager
var traps: Array[Trap] = []
var is_functional: bool = true
@onready var trap_scene:Trap = $Trap

func get_traps() -> void:
	traps.clear()
	for child in get_children():
		if child is Trap:
			traps.append(child)

func add_trap(trap: Trap, coord: Vector2i) -> void:
	if trap in traps:
		return
	if map_manager.spawn_entity(trap, coord):
		traps.append(trap)
		add_child(trap)

		trap.connect("activation", Callable(self, "_on_trap_activated"))
		trap.connect("destroyed", Callable(self, "_on_trap_destroyed"))
		trap.connect("dismantled", Callable(self, "_on_trap_dismantled"))

func _on_trap_activated(trap: Trap) -> void:
	print("Trap activated:", trap.name)

func _on_trap_destroyed(trap: Trap) -> void:
	remove_trap(trap)

#func _on_trap_dismantled(trap: Trap) -> void:

func remove_trap(trap: Trap) -> void:
	if trap in traps:
		if map_manager.map_dict.has(trap.cur_pos):
			map_manager.map_dict.erase(trap.cur_pos)
		traps.erase(trap)
		if is_instance_valid(trap):
			trap.queue_free()

			#inprog ngl of course all of this is inspiration from aaron if not imitation but i am building it out still
func create_trap_from_res(res:Trap)->Trap:
	var trapper :Trap = trap_scene.instantiate()
	add_child(trapper)

	trapper.t_res = res
	trapper.load_unit_res(res)
	trapper.ready_entity()
	trapper.add_to_group("Trap")
	return trapper

func create_trap_from_unit(unit: Node, trap_scene: PackedScene, coord: Vector2i) -> void:
	var new_trap: Trap = trap_scene.instantiate()
	add_trap(new_trap, coord)
	print(unit.name, "created a new trap at", coord)
