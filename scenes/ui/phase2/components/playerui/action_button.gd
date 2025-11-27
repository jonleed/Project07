extends PanelContainer

@export var action_texture_rect:TextureRect
@export var action_butt:Button
@export var dmg_label: Label
#how we fix the needing to connect to button directly
signal action_pressed(act:Action)

func load_action(act:Action):
	if act.action_icon:
		set_action_icon(act.action_icon)
	action_butt.text = act.action_name
	action_butt.tooltip_text = act.tool_tip
	if "dmg" in act:
		dmg_label.text = "DMG: " + str(int(act.dmg))
		dmg_label.add_theme_color_override("font_color", Color.RED)
	elif "heal" in act:
		dmg_label.text = "HEAL: " + str(int(act.heal))
		dmg_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		pass
	
	#disconnect if already connected to not have double emit
	if action_butt.pressed.is_connected(emit_action_pressed):
		action_butt.pressed.disconnect(emit_action_pressed)
	action_butt.pressed.connect(emit_action_pressed.bind(act))
#emit the action
func emit_action_pressed(act:Action):
	action_pressed.emit(act)

#set the icon texture for the action itself
func set_action_icon(texture):
	if texture is Texture2D:#given texture is a loaded texture2D
		action_texture_rect.texture = texture
	elif texture is String:#given texture is a filepath
		var val = load(texture)
		if val and val is Texture2D:
			action_texture_rect.texture = val
