extends Control


func _on_main_menu_pressed() -> void:
	get_tree().callv("change_scene_to_file",["res://scenes/ui/main/Main-Menu.tscn"])

func set_visibility(bul:bool):
	visible = bul
