extends Resource
class_name UnitResource
@export_category("Unit Variables")
@export var action_array:Array[Action]
@export var action_max:int = 1
@export var move_max:int = 5

@export_category("Cosmetic")
@export var icon_sprite:Texture2D = null
@export var unit_name:String = "Joe"
@export_multiline var unit_desc:String = ""
@export_category("Entity Variables")
@export var base_health:int = 5
@export var immortal:bool = false
@export var entity_shape:Pattern2D = load("res://resources/range_patterns/Single Square.tres")

##This category is for the sprite work as out sprite sheets are different
@export_subgroup("Entity Sprite")
##The anim frames that set this entity up
@export var anim_frames:SpriteFrames

@export_subgroup("AI Resource")
@export var ai_res:AIResource
