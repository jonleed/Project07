extends Node2D
class_name Entity
##This will represent something that takes up space on the map
#something that takes up space on the map can take damage, be immortal, and has a current position
##The Entity stats just represents how much space and how big the entity is
@export_subgroup("Entity Stats")
signal health_changed(changed_node:Entity)
##the base health of the entity, when initialized
@export var base_health:int = 10
var health:int = 0:
	set(value):
		if not immortal:
			health = value
		health_changed.emit(self)
@export var immortal:bool = false
@export var entity_shape:Pattern2D = load("res://resources/range_patterns/Single Square.tres")

##This category is for the sprite work as out sprite sheets are different
@export_subgroup("Entity Sprite")
##The anim frames that set this entity up
@export var anim_frames:SpriteFrames
@onready var anim_sprite:AnimatedSprite2D = $AnimatedSprite2D

func ready_entity():
	#init health
	health = base_health
	#init animation
	anim_sprite.sprite_frames = anim_frames
	if anim_frames.get_animation_names().has("Idle"):
		anim_sprite.animation = "Idle"

##this current position represents the tile coordinate the entity is on
var cur_pos:Vector2i = Vector2i.ZERO
