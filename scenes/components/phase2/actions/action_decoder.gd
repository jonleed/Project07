extends Node
class_name ActionDecoder

@export var map_manager:MapManager

#this action decoder takes the action and performs the duty of each action relative to the map
#call this directly to perform the action, the check for which Entity performs this should be done elsewhere
func _ready() -> void:
	print("[ActionDecoder] Ready:", self)


func decode_action(act:Action,targets:Array[Entity]):
	if targets.is_empty():
		return
	if act is Attackaction:
		for target:Entity in targets:
			target.health-=act.dmg
	elif act is Moveaction:
		if targets.size()>1:
			printerr("more than one target, still only accessing one target")
		map_manager.entity_move(targets.get(0).cur_pos,act.chosen_pos)
	elif act is Healaction:
		for target:Entity in targets:
			target.health+= act.heal
	##just add on to the elif tree here for more decoded actions
