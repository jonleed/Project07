extends Control


func _on_start_pressed() -> void:
	Globals.play_ui_sound("Confirm")
	get_tree().change_scene_to_file("res://scenes/components/phase1/Phase-1.tscn")

func _on_quit_pressed() -> void:
	Globals.play_ui_sound("Cancel")
	await Globals.sound_finished
	get_tree().quit()
