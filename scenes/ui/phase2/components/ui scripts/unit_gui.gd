extends Control

# Todo: Implement finalized Unit variable names

@onready var player_unit_manager: Player_Unit_Manager = get_parent().player_unit_manager

func _ready():
	player_unit_manager.connect("update_unit_display", Callable(self, "_on_update_unit_display"))

# Given array of Player Units, Updates UnitGUI
func _on_update_unit_display(units):
	await get_tree().process_frame
	# Show boxes based on number of units
	var count = units.size()
	var displayed_units:Dictionary
	if count<=0:
		return
	
	for child in $HBoxContainer.get_children():
		child.visible = false
	
	for i in count:
		var box = $HBoxContainer.get_child(i)
		var unit = units[i]
		_populate_unit_box(box,unit,i)
		if is_instance_valid(unit):
			if unit.move_count>0 or unit.action_count>0:
				box.modulate = Color.WHITE
			else:
				box.modulate = Color.DIM_GRAY
			box.visible = true
	
	#for i in range(4):
		#var box = $HBoxContainer.get_node("UnitBox%d" % (i + 1))
		##set visibility by validity
		##box.visible = i < count
		#
		#if i < count:
			#var unit = units[i]
			###do get or add logic to hide already displayed units
			#if displayed_units.get(unit,false) or unit == null:
				#box.visible = false
			#else:
				#displayed_units.set(unit,unit)
				#box.visible = true
			#
			#_populate_unit_box(box, unit, i)


# Populates Portaits and HP
func _populate_unit_box(box, unit, index): 
	if not unit:
		return
	print("Populating UnitGUI for ", unit.name)
	# Populate Portraits
	var unit_portrait = box.get_node("UnitSelClassCenterContainer/ClassIconTexture")
	if unit.icon_sprite != null:
		unit_portrait.texture = unit.icon_sprite

	# Populate Selected Unit Name
	if index == 0:
		var unit_label = $UnitPanelHeader/ClassPanelCenterer/ClassLabel
		unit_label.text = unit.unit_name

	# Populate Hearts for all Units
	_update_hearts(box, unit.health, unit.base_health) ## Update to real names

	# Connects signals for selectable unit portraits (2–4)
	if index > 0:
		var button:TextureButton = box.get_node("UnitSelClassCenterContainer/UnitSelClassTextureButton")
		
		# Populate Unit Portraits
		if unit.icon_sprite != null:
			button.texture_normal = unit.icon_sprite
		
		for connection:Dictionary in button.pressed.get_connections():
			#[{"callable":balls()}]
			#signal
			#callable
			#flags
			button.pressed.disconnect(connection["callable"])
		#button.pressed.disconnect_all() # ensure clean reconnects # check if necessary
		button.pressed.connect(func(): _on_unit_selected(unit))

# Shows/hides hearts depending on HP
func _update_hearts(box, current_health: int, max_health: int):
	current_health = clamp(current_health, 0, max_health) # Clamp current HP
	var hearts = box.get_node("UnitSelHealthBar/HealthBarMover/HBoxContainer").get_children()
	for i in range(hearts.size()):
		hearts[i].visible = i < current_health and i < max_health

# Selects Unit from Portrait UI
func _on_unit_selected(unit):
	if not is_instance_valid(unit):
		_on_update_unit_display(player_unit_manager.units)
		return
	player_unit_manager.is_acting = false
	player_unit_manager._on_unit_selected(unit)
