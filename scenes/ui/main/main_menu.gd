extends Control

func _ready() -> void:
	Globals.play_music("Menu",true)

func _on_start_pressed() -> void:
	Globals.play_ui_sound("Confirm")
	get_tree().change_scene_to_file("res://scenes/components/phase1/Phase-1.tscn")

func _on_quit_pressed() -> void:
	Globals.play_ui_sound("Cancel")
	await Globals.sound_finished
	get_tree().quit()


func _on_open_logs_pressed() -> void:
	Logs.open_saved_file()


func _on_settings_pressed() -> void:
	$SoundOptions.visible = true
