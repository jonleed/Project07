extends Control

# Todo: Integrate Item System
# Update Unit variable names
# recovery_amount, base_attack, move_dist, abilities, passive.icon?
# enable _on_unit_health_changed
# action_selected?

@onready var player_unit_manager: Unit_Manager = get_parent().get_parent().player_unit_manager
# Buttons
@onready var recovery_btn = $StatPanelHeader/RecoveryContainer/RecoveryBTN
@onready var action_one_btn = $ActionPanelHeader/ActionPanel/ActionOneContainer/ActionOneBTN
@onready var action_two_btn = $ActionPanelHeader/ActionPanel/ActionTwoContainer/ActionTwoBTN
# @onready var item_btn = $ActionPanelHeader/ActionPanel/ItemContainer/ItemVBoxContainer/ItemBTN
# @onready var item_cycle_up_btn = $ActionPanelHeader/ActionPanel/ItemContainer/ItemVBoxContainer/ItemCycleUp
# @onready var item_cycle_down_btn = $ActionPanelHeader/ActionPanel/ItemContainer/ItemVBoxContainer/ItemCycleDown
# Labels
@onready var base_damage_label = $StatPanelHeader/BaseDamagePanelContainer/Label
@onready var move_dist_label = $StatPanelHeader/MovementPanelContainer/Label
# Containers
@onready var action_one_container = $ActionPanelHeader/ActionPanel/ActionOneContainer
@onready var action_two_container = $ActionPanelHeader/ActionPanel/ActionTwoContainer
@onready var passive_container = $ActionPanelHeader/ActionPanel/PassiveContainer

var heal_amount : int = 1

func _ready():
	player_unit_manager.connect("unit_selected", Callable(self, "_on_unit_selected"))

	# Connect Recovery button
	recovery_btn.pressed.connect(_on_recovery_pressed)

	# Connect Ability buttons
	action_one_btn.pressed.connect(_on_action_one)
	action_two_btn.pressed.connect(_on_action_two)
	
	# Connect Item Buttons
	#$ActionPanelHeader/ActionPanel/ItemContainer/ItemVBoxContainer/ItemBTN
	#$ActionPanelHeader/ActionPanel/ItemContainer/ItemVBoxContainer/ItemCycleUp
	#$ActionPanelHeader/ActionPanel/ItemContainer/ItemVBoxContainer/ItemCycleDown

# Called when current unit updates
func _on_unit_selected(unit):
	_update_stats(unit)
	_update_recovery(unit)
	_update_abilities(unit)
	_update_passive(unit)

# Update base stats (damage / movement)
func _update_stats(unit):
	base_damage_label.text = str(unit.base_attack)
	move_dist_label.text = str(unit.move_dist)

# Update recovery section
func _update_recovery(unit):
	heal_amount = unit.recovery_amount

func _on_recovery_pressed():
	#player_unit_manager._on_unit_health_changed(heal_amount)
	return


# Update current unit abilities 
func _update_abilities(unit):
	var abilities = unit.abilities

	# Hide both by default
	action_one_container.visible = false
	action_two_container.visible = false

	if abilities.size() >= 1:
		var a1 = abilities[0]
		var btn1 = action_one_btn
		btn1.text = a1.name
		action_one_container.visible = true

	if abilities.size() >= 2:
		var a2 = abilities[1]
		var btn2 = action_two_btn
		btn2.text = a2.name
		action_two_container.visible = true


func _on_action_one():
	player_unit_manager.emit_signal("action_selected", {"type": "actionone"})

func _on_action_two():
	player_unit_manager.emit_signal("action_selected", {"type": "actiontwo"})

# Update passive ability
func _update_passive(unit):
	if unit.passive:
		passive_container.visible = true
		var icon = passive_container.get_node("PassiveIcon")
		#icon.texture = unit.passive.icon
	else:
		passive_container.visible = false
