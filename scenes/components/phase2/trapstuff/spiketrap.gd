extends Trap
class_name SpikeTrap

@export var attack_action: Attackaction
@onready var trigger_area: Area2D = $Area2D

func _ready() -> void:
	trigger_area.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node) -> void:
	print("boom", body.name)
	var entity = body.get_parent() if body.get_parent() is Entity else null
	if has_activated or not is_functional:
		return
	has_activated = true
	print("boom ded:", entity.name)
	on_activate(body)

func on_activate(body: Node = null) -> void:
	if attack_action:
		attack_action.executeAttack(self, body)
