extends PanelContainer

var cur_res:UnitResource
@export_subgroup("Control Nodes")
@export var unit_label:Label
@export var unit_texture:TextureRect
@export var rich_text:RichTextLabel
@export var unit_button:Button

func load_unit_res(u_res:UnitResource):
	if not u_res:
		return
	unit_label.text = u_res.unit_name
	unit_texture.texture = u_res.icon_sprite
	#rich_text.text = u_res.unit_desc
	rich_text.text = ""
	rich_text.append_text(u_res.unit_desc)
	cur_res = u_res

func button_disabled(bul:bool):
	unit_button.disabled = bul

signal unit_chosen(res:UnitResource)
func _on_button_pressed() -> void:
	Globals.play_ui_sound("Confirm")
	unit_chosen.emit(cur_res)
