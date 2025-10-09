extends Control

@onready var turn_manager: Turn_Manager = get_parent().get_parent().turn_manager

@export var display_time: float = 2.0
@export var fade_time: float = 1.0

@onready var label = $TurnBannerCenterer/TurnBannerLabel
@onready var background = $TurnBannerCenterer/TurnBannerBackground

func _ready():
	visible = false
	turn_manager.turn_banner_update.connect(show_banner)

func show_banner(banner_text: String):
	label.text = banner_text + "'s Turn"
	fade_in()
	# Wait display_time then fade out
	await get_tree().create_timer(display_time).timeout
	await fade_out()

func fade_in():
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 0, fade_time)
	tween.tween_property(background, "modulate:a", 0, fade_time)
	tween.play()
	await tween.finished
	tween.kill()

func fade_out():
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 1, fade_time)
	tween.tween_property(background, "modulate:a", 0, fade_time)
	tween.play()
	await tween.finished
	tween.kill()
