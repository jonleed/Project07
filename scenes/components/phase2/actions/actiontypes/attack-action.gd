extends Action
class_name Attackaction
@export var base_dmg:int = 0:
	set(value):
		base_dmg = value
		dmg = float(base_dmg)*dmg_mult
@export var dmg_mult:float = 1.0:
	set(value):
		dmg_mult = value
		dmg = float(base_dmg)*dmg_mult
var dmg : float = float(base_dmg)*dmg_mult

func executeAttack(user, target):
		#we gotta see how target in sight is handled(general manager for this might be best)
		#will use placeholder for now to implement can be changed later when manager is done?
	if(target.inView == 1 && user.action_count <=1): #if target in view allow attack
		target.isHurt(dmg)
		print("oof")
	print("Nope") #no attack executed if not in view
