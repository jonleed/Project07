class_name Trap_Manager
extends Node

@export var map_manager: MapManager
var traps: Array[Trap] = []
var is_functional: bool = true
@export var action_decoder: ActionDecoder

func _ready() -> void:
	await get_tree().process_frame
	for trap in get_tree().get_nodes_in_group("Trap"):
		trap.connect("trap_ready", Callable(self, "_on_trap_ready"))
	# If no decoder manually set, find global one
	if action_decoder != null:
		var decoders = get_tree().get_nodes_in_group("ActionDecoder")
		for node in decoders:
			if node is ActionDecoder:
				action_decoder = node
				print("[Trap_Manager] Found global ActionDecoder:", action_decoder)
				break
	if action_decoder == null:
		push_warning("[Trap_Manager] No ActionDecoder found in global group 'Trap'!")

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
		trap.action_decoder = action_decoder
		trap.connect("activation", Callable(self, "_on_trap_activated"))
		trap.connect("destroyed", Callable(self, "_on_trap_destroyed"))
		trap.connect("dismantled", Callable(self, "_on_trap_dismantled"))

func _on_trap_activated(trap: Trap) -> void:
	print("Trap activated:", trap.name)

func _on_trap_destroyed(trap: Trap) -> void:
	traps.erase(trap)
	var pos = trap.grid_pos
	if map_manager.trap_dict.has(pos):
		map_manager.trap_dict.erase(pos)
		map_manager.astar.set_point_solid(pos, false) # still walkable
		trap.queue_free()

#func _on_trap_dismantled(trap: Trap) -> void:

func remove_trap(trap: Trap) -> void:
	if trap in traps:
		if map_manager.map_dict.has(trap.cur_pos):
			map_manager.map_dict.erase(trap.cur_pos)
		traps.erase(trap)
		if is_instance_valid(trap):
			trap.queue_free()

			#inprog ngl of course all of this is inspiration from aaron if not imitation but i am building it out still
func create_trap_from_res(res:PackedScene) -> Trap:
	var trapper:Trap = res.instantiate()
	add_child(trapper)
	trapper.add_to_group("Trap")
	trapper.action_decoder = action_decoder
	return trapper
