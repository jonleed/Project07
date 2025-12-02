extends Control


func _on_continue_pressed() -> void:
	Globals.play_ui_sound("Confirm")
	Globals.play_music("Game",true)
	get_tree().change_scene_to_file("res://scenes/components/debug/levelexample/levelexample.tscn")
