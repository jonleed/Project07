extends Trap
class_name Contact_Trap

@export var attack_action: Attackaction
@export var trap_damage: int = 1
@onready var trigger_area: Area2D = $Area2D

func setup_trap_specific_variables() -> void:
	pass

func _ready() -> void:
	#make a unique copy so no goofs on unit resources
	setup_trap_specific_variables()
	var trap_action := Attackaction.new()
	trap_action.dmg = trap_damage
	#if attack_action:
	#	attack_action = attack_action.duplicate(true)
	#attack_action.base_dmg = trap_damage
	#attack_action.dmg_mult = 1.0
	#connect trigger
	trigger_area.body_entered.connect(_on_body_entered)
	if action_decoder == null:
		var manager = get_tree().get_root().find_child("Trap_Manager", true, false)
		if manager:
			action_decoder = manager.action_decoder
		else:
			print("No decoder")

func _on_body_entered(body: Node) -> void:
	var entity := find_entity(body)
	print("FOUND ENTITY:", entity, " is_entity:", entity is Entity)
	if entity == null:
		print("No Entity found")
		return
	if has_activated or not is_functional:
		print("not functional or already activated")
		return
	has_activated = true
	on_activate(entity)
	print("boom ded:", entity.name)

func on_activate(node = null) -> void:
	var bodies = $Area2D.get_overlapping_bodies()
	#maybe modify for bigger spike(?) trap?
	var targets: Array[Entity] = []
	for b in bodies:
		print("[TRAP] Checking:", b)
		var ent = find_entity(b)
		if ent != null:
			print("[TRAP] FOUND TARGET:", ent)
			targets.append(ent)
		else:
			print("[TRAP] No target found for:", b)
	if targets.is_empty():
		print("[TRAP] No valid targets")
		return
	var trap_action := Attackaction.new()
	trap_action.dmg = trap_damage 
	var typed_targets: Array[Entity] = targets
	#action_decoder.decode_action(trap_action, typed_targets, self)
	trap_action.execute(typed_targets)

	#was tempted to do the recursive version to make it spooky but we left that in cs1
func find_entity(node: Node) -> Entity:
	var current = node
	while current != null:
		if current is Entity:
			return current
		current = current.get_parent()
	return null
