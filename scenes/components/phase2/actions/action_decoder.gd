extends Node
class_name ActionDecoder

@export var map_manager:MapManager

#this action decoder takes the action and performs the duty of each action relative to the map
#call this directly to perform the action, the check for which Entity performs this should be done elsewhere


func decode_action(act:Action,targets:Array[Entity], curUnit: Entity):
	#if targets.is_empty(): return
	if act is Attackaction:
		for target:Entity in targets:
			target.health-=act.dmg
			if target is Hostile_Unit:
				target.last_unit_to_damage_me = curUnit
			Globals.play_ui_sound("Basic_Attack")
	elif act is Moveaction:
		if targets.size()>1:
			printerr("more than one target, still only accessing one target")
		map_manager.entity_move(targets.get(0).cur_pos,act.chosen_pos)
	elif act is Healaction:
		for target:Entity in targets:
			target.health+= act.heal
		Globals.play_ui_sound("Support_Heal")
	elif act is Takeaction: # Take like in Chess; I thought it was a clever name...
		if targets.size()>=2:
			printerr("Take requires less than two unit in targets")
			return
		if targets.size()==1:
			var target_pos = targets.get(0).cur_pos
			targets.get(0).health-=act.dmg
			if targets.get(0) is Hostile_Unit:
				targets.get(0).last_unit_to_damage_me = curUnit
			if targets.get(0).health <= 0:
				await map_manager.entity_move(curUnit.cur_pos,target_pos)
				curUnit.action_count +=1
		else: # Move without attacking
			await map_manager.entity_move(curUnit.cur_pos,act.chosen_pos)
		Globals.play_ui_sound("Heavy_Attack")
	elif act is Swapaction:
		if targets.size()!=1:
			printerr("Swap requires one unit in targets")
			return
		map_manager.swap_entities(curUnit,  targets.get(0))
		Globals.play_ui_sound("Swap_Magic")
	elif act is Pushaction:
		if targets.size()!=1:
			printerr("Push requires one unit in targets")
			return
		var target: Entity = targets.get(0)
		# Apply base damage
		target.health -= act.dmg
		# Determine push direction: away from actor
		var diff: Vector2i = target.cur_pos - curUnit.cur_pos
		var direction: Vector2i = Vector2i(
			sign(diff.x),
			sign(diff.y)
		)
		var new_pos: Vector2i = target.cur_pos + direction
		# Check new pos for walls or entities
		var entity_at_new = map_manager.map_dict.get(new_pos, null)
		var tile_at_new = map_manager.get_surface_tile(new_pos)
		if tile_at_new == 5: # Out of bounds
			print("Pushed out of bounds; bonus damage")
			if target is Hostile_Unit:
				target.last_unit_to_damage_me = curUnit
			target.health -= act.bonus_dmg
		elif entity_at_new == null and tile_at_new != 5: # Free tile, move target
			print("Pushed into free tile")
			map_manager.entity_move(target.cur_pos, new_pos)
		elif entity_at_new is int: # Pushed into wall
			print("Pushed into wall; bonus damage")
			if target is Hostile_Unit:
				target.last_unit_to_damage_me = curUnit
			target.health -= act.bonus_dmg
		else: # Pushed into entity
			print("Pushed into entity; bonus damage")
			if target is Hostile_Unit:
				entity_at_new.last_unit_to_damage_me = curUnit
				target.last_unit_to_damage_me = curUnit
			entity_at_new.health -= act.bonus_dmg
			target.health -= act.bonus_dmg
	
	##just add on to the elif tree here for more decoded actions
