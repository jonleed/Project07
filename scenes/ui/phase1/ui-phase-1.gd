extends Node

var unit_array:Array = []

func add_unit():
	update_proceed_button()

func remove_unit():
	update_proceed_button()

func update_proceed_button():
	$"Control/Proceed to Phase 2".disabled = unit_array.size()<3


func _on_proceed_to_phase_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/components/debug/GUItest/guitestscene.tscn")
