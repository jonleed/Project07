extends Control

# Todo: Implement finalized Unit variable names

@onready var player_unit_manager: Unit_Manager = get_parent().get_parent().player_unit_manager

func _ready():
	player_unit_manager.connect("update_unit_display", Callable(self, "_on_update_unit_display"))

# Given array of Player Units, Updates UnitGUI
func _on_update_unit_display(units):
	# Show boxes based on number of units
	var count = units.size()
	for i in range(4):
		var box = $HBoxContainer.get_node("UnitBox%d" % (i + 1))
		box.visible = i < count

		if i < count:
			var unit = units[i]
			_populate_unit_box(box, unit, i)

# Populates Portaits and HP
func _populate_unit_box(box, unit, index): 
	print("Populating UnitGUI for ", unit.name)
	# Populate Portraits
	#var unit_portrait = box.get_node("UnitSelClassCenterContainer/ClassIconTexture")
	#unit_portrait.texture = unit.portrait ## Update to real names

	# Populate Selected Unit Name
	if index == 0:
		var unit_label = $UnitPanelHeader/ClassPanelCenterer/ClassLabel
		unit_label.text = unit.name

	# Populate Hearts for all Units
	_update_hearts(box, unit.health, unit.base_health) ## Update to real names

	# Connects signals for selectable unit portraits (2–4)
	if index > 0:
		var button = box.get_node("UnitSelClassCenterContainer/UnitSelClassTextureButton")
		button.pressed.disconnect_all() # ensure clean reconnects
		button.pressed.connect(func(): _on_unit_selected(unit))

# Shows/hides hearts depending on HP
func _update_hearts(box, current_health: int, max_health: int):
	current_health = clamp(current_health, 0, max_health) # Clamp current HP
	var hearts = box.get_node("UnitSelHealthBar/HealthBarMover/HBoxContainer").get_children()
	for i in range(hearts.size()):
		hearts[i].visible = i < current_health and i < max_health

# Selects Unit from Portrait UI
func _on_unit_selected(unit):
	player_unit_manager._on_unit_selected(unit)
