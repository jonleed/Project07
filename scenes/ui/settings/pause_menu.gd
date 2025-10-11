extends PanelContainer

func _on_main_menu_pressed() -> void:
	Globals.play_ui_sound("Confirm")
	$ConfirmationDialog.popup_centered()

func _on_open_options_pressed() -> void:
	Globals.play_ui_sound("Confirm")
	$Options.visible = true

func _on_confirmation_dialog_confirmed() -> void:
	Globals.play_ui_sound("Cancel")
	get_tree().change_scene_to_file("res://scenes/ui/main/Main-Menu.tscn")

func _on_confirmation_dialog_canceled() -> void:
	Globals.play_ui_sound("Cancel")
	$ConfirmationDialog.visible = false


func _on_close_pressed() -> void:
	Globals.play_ui_sound("Confirm")
	visible = false
