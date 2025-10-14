extends Node

@export var turn_manager : Turn_Manager
@export var player_unit_manager: Unit_Manager

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			match event.keycode:
				KEY_ESCAPE:
					$PauseMenu.visible = not $PauseMenu.visible
