extends Trap
class_name SpikeTrap

@export var attack_action: Attackaction
@onready var trigger_area: Area2D = $Area2D


func _ready() -> void:
	trigger_area.body_entered.connect(_on_body_entered)
	if action_decoder == null:
		var manager = get_tree().get_first_node_in_group("TrapManager")
		print("[SpikeTrap] Found TrapManager:", manager)
		if manager:
			action_decoder = manager.action_decoder
			print("[SpikeTrap] Assigned decoder:", action_decoder)


func _on_body_entered(body: Node) -> void:
	print("boom", body.name)
	var entity = body.get_parent() if body.get_parent() is Entity else null
	if has_activated or not is_functional:
		print("thats the issue")
		return
	has_activated = true
	print("boom ded:", entity.name)
	on_activate(body)


func on_activate(body: Node = null) -> void:
	var decoder = get_tree().get_root().find_child("ActionDecoder", true, false)
	if action_count < 1:
		var parent_entity = body.get_parent()
		#decoder.decode_action(attack_action, [parent_entity])
		decoder.decode_action(attack_action, [parent_entity] as Array[Entity])
