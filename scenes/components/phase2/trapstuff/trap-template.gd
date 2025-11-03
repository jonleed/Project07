#we need to look into trap placement
#tile gen
extends Entity
class_name Trap

@export_subgroup("Base Trap Values")
@export var vision_dist: int = 5

signal activation(trap: Trap)
signal destroyed(trap: Trap)
signal dismantled(trap: Trap)

var has_activated: bool = false
var is_functional: bool = true

func _ready() -> void:
	ready_entity()
	connect("health_changed", Callable(self, "_on_health_changed"))

func _on_health_changed(changed_node: Entity) -> void:
	if health <= 0 and not immortal:
		on_destroy()

func dismantle_trap() -> void:
	if not is_functional:
		return
	is_functional = false
	print(name, "was dismantled.")
	emit_signal("dismantled", self)

func on_destroy() -> void:
	if not is_functional:
		return
	is_functional = false
	print(name, "was destroyed.")
	emit_signal("destroyed", self)
	queue_free()

func get_trap_status() -> bool:
	emit_signal("activation", self)
	return has_activated

func on_activate(_body: Node = null) -> void:
	pass  
