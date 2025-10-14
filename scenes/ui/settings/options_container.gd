extends Control
func _on_back_pressed() -> void:
	Globals.play_ui_sound("Cancel")
	visible = false
