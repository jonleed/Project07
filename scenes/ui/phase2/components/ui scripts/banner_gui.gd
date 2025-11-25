extends Control

@onready var turn_manager: Turn_Manager = get_parent().turn_manager
@onready var round_initalizer: RoundInitializer = get_parent().round_initalizer

@export var display_time: float = 1.5
@export var fade_time: float = 0.4

@onready var label = $TurnBannerCenterer/TurnBannerLabel
@onready var background = $TurnBannerCenterer/TurnBannerBackground

func _ready():
	visible = false
	label.modulate.a = 0.0
	background.modulate.a = 0.0
	round_initalizer.turn_banner_update.connect(show_banner)
	#turn_manager.turn_banner_update.connect(show_banner)

func show_banner(banner_text: String):
	visible = true
	label.text = banner_text
	await fade_in()
	# Wait display_time then fade out
	await get_tree().create_timer(display_time).timeout
	await fade_out()

func fade_in() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(background, "modulate:a", 1.0, fade_time)
	await tween.finished
	tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 1.0, fade_time)
	await tween.finished

func fade_out() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 0.0, fade_time)
	tween.tween_property(background, "modulate:a", 0.0, fade_time)
	await tween.finished
