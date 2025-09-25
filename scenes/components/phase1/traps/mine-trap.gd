extends Trap
class_name MineTrap
@export  var attack_action: Attackaction
func _on_body_entered(_body:Node)->void:
#no need for if unless traps gain action in between turns but would be kinda hacky
	print("boom")
	attack_action.executeAttack(self,_body)
	attack_action.executeAttack(self,self)
