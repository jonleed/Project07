extends Control


func set_visibility(bul:bool):
	visible = bul

func _on_return_pressed() -> void:
	self.set_visibility(false)
