extends Node

@export var pat:Pattern2D

func _ready() -> void:
	if pat:
		pat.debug()
