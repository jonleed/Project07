@tool
extends EditorPlugin

const InspectorPlugin = preload("res://addons/pattern_2d_editor/pattern2dinspector.gd")
var inspector_plugin = InspectorPlugin.new()

func _enter_tree():
	# Add the custom inspector plugin to the editor
	inspector_plugin.editor_plugin_instance = self
	inspector_plugin._current_pattern = Pattern2D.new()
	add_inspector_plugin(inspector_plugin)

func _exit_tree():
	# Clean up when the plugin is disabled
	remove_inspector_plugin(inspector_plugin)
