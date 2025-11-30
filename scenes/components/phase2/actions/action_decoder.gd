extends Node
class_name ActionDecoder

@export var map_manager:MapManager
@export var trap_manager:Trap_Manager
var trap_scenes = [preload("res://scenes/components/phase2/trapstuff/spiketrap.tscn"), preload("res://scenes/components/phase2/trapstuff/fire.tscn")]

#this action decoder takes the action and performs the duty of each action relative to the map
#call this directly to perform the action, the check for which Entity performs this should be done elsewhere


func decode_action(act:Action,targets:Array[Entity], curUnit: Entity):
	#if targets.is_empty(): return
	if act is Attackaction:
		var targets_to_damage: Array[Entity] = []
		if act.all_tile_attack:
			# Deal damage to all entities in the attack pattern range
			var assembled_tiles: Array[Vector2i] = []
			if act.range_type == 0:
				assembled_tiles = Globals.get_scaled_pattern_tiles(curUnit.cur_pos, act.range_pattern, act.range_dist, map_manager)
			elif act.range_type == 1:
				assembled_tiles = Globals.get_bfs_tiles(curUnit.cur_pos, act.range_dist, map_manager)
			
			# Collect all entities on the assembled tiles
			for tile in assembled_tiles:
				var entity = map_manager.map_dict.get(tile, null)
				if entity != null and entity is Entity and entity != curUnit:
					targets_to_damage.append(entity)
		else:
			# Use the provided targets
			targets_to_damage = targets
		
		# Apply damage to all targets
		for target: Entity in targets_to_damage:
			target.health -= act.dmg
			if target is Hostile_Unit:
				target.last_unit_to_damage_me = curUnit
			Globals.play_ui_sound("Basic_Attack")
			if target.health <= 0:
				curUnit.health += act.heal_on_kill
	elif act is Moveaction:
		if targets.size()>1:
			printerr("more than one target, still only accessing one target")
		map_manager.entity_move(targets.get(0).cur_pos,act.chosen_pos)
	elif act is Healaction:
		var targets_to_heal: Array[Entity] = []
		if act.all_tile_heal:
			# Heal all entities in the heal pattern range
			var assembled_tiles: Array[Vector2i] = []
			if act.range_type == 0:
				assembled_tiles = Globals.get_scaled_pattern_tiles(curUnit.cur_pos, act.range_pattern, act.range_dist, map_manager)
			elif act.range_type == 1:
				assembled_tiles = Globals.get_bfs_tiles(curUnit.cur_pos, act.range_dist, map_manager)
			
			# Collect all entities on the assembled tiles
			for tile in assembled_tiles:
				var entity = map_manager.map_dict.get(tile, null)
				if entity != null and entity is Entity:
					targets_to_heal.append(entity)
		else:
			# Use the provided targets
			targets_to_heal = targets
		
		# Apply healing to all targets
		for target: Entity in targets_to_heal:
			target.health += act.heal
			target.health = clamp(target.health, 0, target.base_health)
			print("Healing target, %s for %s." % [target, act.heal])
		
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
			# Validate that chosen_pos is within valid range
			var assembled_tiles: Array[Vector2i] = []
			if act.range_type == 0:
				assembled_tiles = Globals.get_scaled_pattern_tiles(curUnit.cur_pos, act.range_pattern, act.range_dist, map_manager)
			elif act.range_type == 1:
				assembled_tiles = Globals.get_bfs_tiles(curUnit.cur_pos, act.range_dist, map_manager)
			
			# Check if chosen_pos is in valid tiles
			if act.chosen_pos in assembled_tiles:
				await map_manager.entity_move(curUnit.cur_pos, act.chosen_pos)
			else:
				printerr("Invalid move position: ", act.chosen_pos, " not in valid range")
				curUnit.action_count +=1
		Globals.play_ui_sound("Heavy_Attack")
	elif act is Swapaction:
		if targets.size()!=1:
			printerr("Swap requires one unit in targets")
			return
		map_manager.swap_entities(curUnit,  targets.get(0))
		Globals.play_ui_sound("Swap_Magic")
	elif act is Pushaction:
		var targets_to_push: Array[Entity] = []
		
		if act.all_tile_attack:
			# Push all entities in the push pattern range
			var assembled_tiles: Array[Vector2i] = []
			if act.range_type == 0:
				assembled_tiles = Globals.get_scaled_pattern_tiles(curUnit.cur_pos, act.range_pattern, act.range_dist, map_manager)
			elif act.range_type == 1:
				assembled_tiles = Globals.get_bfs_tiles(curUnit.cur_pos, act.range_dist, map_manager)
			
			# Collect all entities on the assembled tiles
			for tile in assembled_tiles:
				var entity = map_manager.map_dict.get(tile, null)
				if entity != null and entity is Entity and entity != curUnit:
					targets_to_push.append(entity)
		else:
			# Use the provided targets
			if targets.size() != 1:
				printerr("Push requires one unit in targets")
				return
			targets_to_push = targets
		
		# Apply push to all targets
		for target: Entity in targets_to_push:
			# Apply base damage
			target.health -= act.dmg
			
			# Determine push direction based on curUnit
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
				await map_manager.entity_move(target.cur_pos, new_pos)
			elif entity_at_new is int: # Pushed into wall
				print("Pushed into wall; bonus damage")
				if target is Hostile_Unit:
					target.last_unit_to_damage_me = curUnit
				target.health -= act.bonus_dmg
			else: # Pushed into entity
				print("Pushed into entity; bonus damage")
				if entity_at_new is Hostile_Unit:
					entity_at_new.last_unit_to_damage_me = curUnit
				if target is Hostile_Unit:
					target.last_unit_to_damage_me = curUnit
				entity_at_new.health -= act.bonus_dmg
				target.health -= act.bonus_dmg
	elif act is Pullaction:
		var targets_to_pull: Array[Entity] = []
		
		if act.all_tile_attack:
			# Pull all entities in the pull pattern range
			var assembled_tiles: Array[Vector2i] = []
			if act.range_type == 0:
				assembled_tiles = Globals.get_scaled_pattern_tiles(curUnit.cur_pos, act.range_pattern, act.range_dist, map_manager)
			elif act.range_type == 1:
				assembled_tiles = Globals.get_bfs_tiles(curUnit.cur_pos, act.range_dist, map_manager)
			
			# Collect all entities on the assembled tiles
			for tile in assembled_tiles:
				var entity = map_manager.map_dict.get(tile, null)
				if entity != null and entity is Entity and entity != curUnit:
					targets_to_pull.append(entity)
		else:
			# Use the provided targets
			if targets.size() != 1:
				printerr("Pull requires one unit in targets")
				return
			targets_to_pull = targets
		
		# Apply pull to all targets
		for target: Entity in targets_to_pull:
			# Base damage
			target.health -= act.dmg
			if target is Hostile_Unit:
				target.last_unit_to_damage_me = curUnit
			
			# Direction toward curUnit 
			var diff: Vector2i = target.cur_pos - curUnit.cur_pos
			var direction := Vector2i(sign(diff.x), sign(diff.y))
			
			# Tile directly in front of curUnit toward the target
			var pull_pos: Vector2i = curUnit.cur_pos + direction
			
			# Cannot pull onto curUnit or invalid direction
			if direction == Vector2i.ZERO:
				print("Pull: target on same tile, nothing to do")
				continue
			
			# Check tile validity
			var entity_at_pull = map_manager.map_dict.get(pull_pos, null)
			
			# If tile free, move target
			if entity_at_pull == null:
				print("Pulled onto free tile")
				await map_manager.entity_move(target.cur_pos, pull_pos)
			else:
				# If tile occupied, bonus damage
				print("Pull blocked; bonus damage")
				target.health -= act.bonus_dmg

	var dropped_trap_on_singlehit_already:bool = false
	print(act.drop_trap_on_singlehit_tile)
	print(act.drop_trap_on_multihit_tiles)
	if act.drop_trap_on_singlehit_tile:
		dropped_trap_on_singlehit_already = true
		var trap_res:PackedScene = trap_scenes[act.trap_for_singlehit]
		var trap_instance:Node2D = trap_res.instantiate()
		trap_manager.add_child(trap_instance)
		trap_manager.add_trap(trap_instance, targets[0].cur_pos)
		trap_instance.position = map_manager.coords_to_glob(targets[0].cur_pos)
	if act.drop_trap_on_multihit_tiles:
		var all_multihit_tiles:Array[Vector2i] = act.multihit_pattern.calculate_affected_tiles_from_center(curUnit.cur_pos)
		for tile:Vector2i in all_multihit_tiles:
			print(tile)
			if dropped_trap_on_singlehit_already and tile == targets[0].cur_pos:
				continue
			var trap_res:PackedScene = trap_scenes[act.trap_for_multihit]
			var trap_instance:Trap = trap_res.instantiate()
			trap_manager.add_child(trap_instance)
			trap_manager.add_trap(trap_instance, tile)
			trap_manager.traps.append(trap_instance)
			trap_instance.position = map_manager.coords_to_glob(tile)
	

	##just add on to the elif tree here for more decoded actions
