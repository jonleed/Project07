extends Camera2D

func _input(event):	
	if event.is_action_pressed("pan_right", true):
		position.x += (5 * scale.x)
	elif event.is_action_pressed("pan_left", true):
		position.x -= (5 * scale.x)
	elif event.is_action_pressed("pan_down", true):
		position.y += (5 * scale.y)
	elif event.is_action_pressed("pan_up", true):
		position.y -= (5 * scale.y)
	elif event.is_action_pressed("zoom_in", true):
		zoom *= 1.25
	elif event.is_action_pressed("zoom_out", true):
		zoom *= 0.75
		
		
