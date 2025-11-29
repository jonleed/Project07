extends Trap
class_name Lever

@onready var trigger_area: Area2D = $Area2D

func _ready() -> void:
	trigger_area.body_entered.connect(_on_body_entered)

func _on_health_changed(_changed_node: Entity) -> void:
	on_activate()

func on_activate(node = null) -> void:
	print("Pull the lever cronk")
	emit_signal("activation", self)

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

func find_entity(node: Node) -> Entity:
	var current = node
	while current != null:
		if current is Entity:
			return current
		current = current.get_parent()
	return null
