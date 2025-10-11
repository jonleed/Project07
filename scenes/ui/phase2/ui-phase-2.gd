@tool
extends Node

@export var turn_manager : Turn_Manager
@export var player_unit_manager: Unit_Manager

func _ready() -> void:
	if Engine.is_editor_hint():
		self.visible = false
	else:
		self.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey:
		if event.is_pressed():
			match event.keycode:
				KEY_ESCAPE:
					$PauseMenu.visible = not $PauseMenu.visible
