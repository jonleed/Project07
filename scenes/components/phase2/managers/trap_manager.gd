class_name Trap_Manager
extends Node

@export var map_manager: MapManager
var traps: Array[Trap] = []
var is_functional: bool = true
@onready var trap_scene: Trap = $Trap
@export var action_decoder: ActionDecoder
#@onready var action_decoder: ActionDecoder = get_parent().get_node("ActionDecoder")
var used_traps: Array = []
signal faction_turn_complete
var faction_name = "Traps"


func _on_turn_started(manager):
	refresh_trap_actions()

func refresh_trap_actions():
	for trap in traps:
		trap.refresh_actions()

func start():
	get_traps()
	if traps.size() == 0:
		end_turn()

func _ready() -> void:
	# listen to turn manager
	get_parent().turn_started.connect(_on_turn_started)
	# gather traps
	get_traps()
	print("[Trap_Manager] Ready, action_decoder =", action_decoder)


func reset_trap_turns() -> void:
	for trap in traps:
		trap.action_count = trap.action_max
		trap.move_count = trap.move_max


#func get_traps():
#   traps.clear()
#  for child in get_children():
#     if child.has_method("refresh_actions"):
#        traps.append(child)


func get_traps() -> void:
	traps.clear()
	for child in get_children():
		if child is Trap:
			traps.append(child)
	reset_traps_turns()


func add_trap(trap: Trap, coord: Vector2i) -> void:
	if trap in traps:
		return
	if map_manager.spawn_entity(trap, coord):
		traps.append(trap)
		trap.action_decoder = action_decoder

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
			map_manager.trap_dict.erase(trap.coord)
			map_manager.update_astar_solidity(trap.coord)
		traps.erase(trap)
		if is_instance_valid(trap):
			trap.queue_free()

			#inprog ngl of course all of this is inspiration from aaron if not imitation but i am building it out still
func create_trap_from_res(res: PackedScene) -> Trap:
	var trapper: Trap = res.instantiate()
	add_child(trapper)
	trapper.add_to_group("Trap")
	trapper.action_decoder = action_decoder
	return trapper

func reset_traps_turns() -> void:
	for traps in traps:
		traps.action_count = traps.action_max

func get_unused_traps() -> Array:
	var unused_traps = []
	for t in traps:
		if t.action_count > 0:
			unused_traps.append(t)
	return unused_traps

func refresh_all_traps():
	for trap in traps:
		trap.action_count = trap.action_max
		trap.move_count = trap.move_max

func activate_traps():
	for trap in traps:
		trap.take_turn()  # Whatever method triggers them

func end_turn():
	print("Trap Manager Turn End")
	emit_signal("faction_turn_complete")
