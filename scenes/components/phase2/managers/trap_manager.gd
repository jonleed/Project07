class_name Trap_Manager
extends Node

@export var map_manager: MapManager
var traps: Array[Trap] = []
var is_functional: bool = true
@onready var trap_scene: Trap = $Trap
@export var action_decoder: ActionDecoder
#@onready var action_decoder: ActionDecoder = get_parent().get_node("ActionDecoder")
var used_traps: Array = []
var faction_name = "Traps"

func _ready() -> void:
	# gather traps
	get_traps()
	print("Trap_Manager Ready, action_decoder =", action_decoder)
	var root := get_tree().current_scene  # NOT get_root(), NOT Window
	if root:
		var turn_manager = root.find_child("Turn_Manager", true, false)
		if turn_manager:
			turn_manager.connect("turn_started", Callable(self, "_on_turn_started"))
		else:
			print("Trap_Manager WARNING: Could not find Turn_Manager")

func reset_trap_turns() -> void:
	for trap in traps:
		trap.action_count = trap.action_max
		trap.move_count = trap.move_max

func get_traps() -> void:
	traps.clear()
	for child in get_children():
		if child is Trap:
			traps.append(child)
	refresh_all_traps()


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

func get_unused_traps() -> Array:
	var unused_traps = []
	for t in traps:
		if t.action_count > 0:
			unused_traps.append(t)
	return unused_traps

func refresh_all_traps():
	for trap in traps:
		trap.action_count = trap.action_max
		trap.refresh_actions()
		
func _on_turn_started(faction_manager: Unit_Manager) -> void:
	if faction_manager.faction_name != "Traps":
		refresh_all_traps()
