@tool
extends EditorInspectorPlugin

# We need a reference to the resource script to check against.
const Pattern2D = preload("res://addons/pattern_2d_editor/pattern2d.gd")

# A reference to the main EditorPlugin, which will be set by plugin.gd
var editor_plugin_instance: EditorPlugin = null
var _current_pattern: Pattern2D = null

# This function tells the editor that this plugin can handle objects of type Pattern2D.
func _can_handle(object) -> bool:
	return object is Pattern2D

# This function is now just used to store a reference to the object.
func _parse_begin(object):
	_current_pattern = object as Pattern2D

# This function is where we now build and add our custom UI.
# It is called for each property in the resource.
func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide) -> bool:
	# We are only interested in replacing the editor for "affected_tiles".
	if name == "affected_tiles":
		# Add a descriptive label for our UI section.
		var label = Label.new()
		label.text = "Affected Tiles Grid:"
		add_custom_control(label)

		# Create a GridContainer to hold our checkboxes.
		var grid = GridContainer.new()
		grid.columns = _current_pattern.grid_size.x
		add_custom_control(grid)

		# Calculate the offset to center the grid on the origin.
		var offset = _current_pattern.grid_size / 2

		# Create a checkbox for each cell in the grid.
		for y_raw in range(_current_pattern.grid_size.y):
			for x_raw in range(_current_pattern.grid_size.x):
				# Calculate the logical, centered position for this cell.
				var pos := Vector2(x_raw - offset.x, y_raw - offset.y)
				
				var checkbox = CheckBox.new()
				checkbox.tooltip_text = str(pos)
				
				# Highlight the origin tile (0,0), which is now the center.
				if pos == Vector2.ZERO:
					checkbox.self_modulate = Color(0.7, 0.9, 1.0) # Light Blue
					checkbox.tooltip_text += " (Origin)"
				
				# This check will now reliably populate the grid.
				checkbox.button_pressed = _current_pattern.affected_tiles.has(pos)
				
				# Connect the toggled signal to our handler function.
				checkbox.toggled.connect(_on_tile_toggled.bind(pos))
				
				grid.add_child(checkbox)
		
		# Tell the inspector we have handled this property, so it doesn't draw the default UI.
		return true

	# For all other properties, let the default inspector handle them.
	return false


# This function is called whenever a checkbox in our grid is clicked.
# NO CHANGES ARE NEEDED HERE, as it works with the logical 'pos' vector.
func _on_tile_toggled(is_pressed: bool, pos: Vector2):
	if not _current_pattern or not editor_plugin_instance:
		return

	# Using UndoRedo allows the user to undo/redo their changes in the editor.
	# We get it from our reference to the main EditorPlugin script.
	var undo_redo: EditorUndoRedoManager = editor_plugin_instance.get_undo_redo()
	var original_tiles = _current_pattern.affected_tiles.duplicate()
	var new_tiles = original_tiles.duplicate()

	if is_pressed:
		if not new_tiles.has(pos):
			new_tiles.append(pos)
	else:
		if new_tiles.has(pos) and new_tiles.find(pos)>=0:
			new_tiles.remove_at(new_tiles.find(pos))

	undo_redo.create_action("Toggle Pattern Tile")
	undo_redo.add_do_property(_current_pattern, "affected_tiles", new_tiles)
	undo_redo.add_undo_property(_current_pattern, "affected_tiles", original_tiles)
	undo_redo.commit_action()
