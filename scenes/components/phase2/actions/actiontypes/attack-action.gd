extends Action
class_name Attackaction
@export var damage :Damage
func executeAttack(user, target):
		#we gotta see how target in sight is handled(general manager for this might be best)
		#will use placeholder for now to implement can be changed later when manager is done?
	if(target.inView == 1 && user.action_count <=1): #if target in view allow attack
		var FinalDamage = damage.FinalDamage()
		target.isHurt(FinalDamage)
		user.action_count -=1
		print("oof")
	print("Nope") #no attack executed if not in view
