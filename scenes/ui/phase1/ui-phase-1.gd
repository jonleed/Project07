extends Node


func _on_proceed_to_phase_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/components/debug/managerstest/testscene.tscn")
