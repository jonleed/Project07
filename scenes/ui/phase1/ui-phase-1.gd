extends Node

var unit_array:Array = []
##this should not change over the course of phase 1
@export_subgroup("Preloads")
@onready var unit_display_packed:PackedScene = preload("res://scenes/components/phase1/unitdisplay/UnitDisplay.tscn")
@export var unit_resources:Array[UnitResource]
@export var max_party:int = 1
var cur_display:Dictionary[Control,UnitResource]

@export_subgroup("Control Nodes")
@export var unit_holder:BoxContainer
@export var cur_party:BoxContainer
@export var party_count:Label
@export var proceed_button:Button

func add_unit(res:UnitResource):
	if unit_array.has(res):
		return
	unit_array.append(res)
	update_proceed_button()

func remove_unit(res:UnitResource):
	if not unit_array.has(res):
		return
	Globals.play_ui_sound("Cancel")
	remove_party_label(res)
	unit_array.erase(res)
	disable_unit_display(res,false)
	update_proceed_button()

func display_unit(res:UnitResource):
	#instantiate unit display
	var un_disp:Control = unit_display_packed.instantiate()
	#add it to holder and add it to the dictionary
	unit_holder.add_child(un_disp)
	cur_display.set(un_disp,res)
	#create and load the resource
	un_disp.load_unit_res(res)
	#connect its signals
	un_disp.unit_chosen.connect(choose_unit)
	#expand the unit to the full expanse of the hbox container
	un_disp.size_flags_vertical = Control.SIZE_EXPAND

func choose_unit(res:UnitResource):
	#find the correct unit display with cur_display
	disable_unit_display(res,true)
	#add label
	var cur_party_label:Label = Label.new()
	cur_party_label.text = res.unit_name
	#add remove button
	var remove_but:Button = Button.new()
	remove_but.text = "X"
	remove_but.pressed.connect(remove_unit.bind(res))
	#add container
	var label_cont:HBoxContainer = HBoxContainer.new()
	label_cont.add_child(cur_party_label)
	label_cont.add_child(remove_but)
	cur_party.add_child(label_cont)
	add_unit(res)

func remove_party_label(res:UnitResource):
	var party_label = cur_party.get_child(unit_array.find(res))
	print(party_label)
	party_label.queue_free()

func disable_unit_display(res:UnitResource,bul:bool):
	var cur_un_disp:Control = cur_display.keys()[cur_display.values().find(res)]
	print(cur_un_disp)
	#disable the button
	cur_un_disp.button_disabled(bul)

func update_proceed_button():
	#if the cur unit array is less than max party and there are more than or equal to max party possible units
	proceed_button.disabled = (not unit_array.size()==max_party) and unit_resources.size()>=max_party
	party_count.text = str(unit_array.size(),"/",max_party)
	

func _ready():
	if not (unit_holder and cur_party and party_count and proceed_button):
		printerr("Missing Control Nodes!!!")
	
	for res:UnitResource in unit_resources:
		display_unit(res)
	
	update_proceed_button()

func _on_proceed_to_phase_2_pressed() -> void:
	Globals.play_ui_sound("Confirm")
	await Globals.sound_finished
	Globals.party_units = unit_array.duplicate(true)
	get_tree().change_scene_to_file("res://scenes/components/debug/GUItest/guitestscene.tscn")
