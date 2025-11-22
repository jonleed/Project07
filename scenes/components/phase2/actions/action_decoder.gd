extends Node
class_name ActionDecoder

@export var map_manager:MapManager

#this action decoder takes the action and performs the duty of each action relative to the map
#call this directly to perform the action, the check for which Entity performs this should be done elsewhere


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
	elif act is Takeaction: # Take like in Chess; I thought it was a clever name...
		## Target[1] is target_unit, Target[0] is cur_unit
		if targets.size()>2:
			printerr("Take requires two units in targets")
		elif targets.size()==2:
			var target_pos = targets.get(1).cur_pos
			targets.get(1).health-=act.dmg
			if targets.get(1).health <= 0:
				await map_manager.entity_move(targets.get(0).cur_pos,target_pos)
				targets.get(0).action_count +=1
		else: # Move without attacking
			await map_manager.entity_move(targets.get(0).cur_pos,act.chosen_pos)
	##just add on to the elif tree here for more decoded actions
