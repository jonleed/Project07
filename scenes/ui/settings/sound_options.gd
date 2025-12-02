extends PanelContainer

@onready var vbox_sounds: VBoxContainer = $"VBoxContainer/PanelContainer/Sound Scrolls"

# This function is called when the node enters the scene tree for the first time.
func _ready() -> void:
	# It's good practice to clear any existing sliders before loading new ones.
	clear_sounds()
	load_busses()

## Closes the options menu by just hiding it.
func _on_close_options_pressed() -> void:
	Globals.play_ui_sound("Cancel")
	visible = false

# Removes all dynamically created sliders from the VBoxContainer.
func clear_sounds() -> void:
	for child in vbox_sounds.get_children():
		child.queue_free()

# Loops through all available audio buses in the project.
func load_busses() -> void:
	for bus_index: int in AudioServer.bus_count:
		connect_slider_to_bus(bus_index)

# Creates and configures a slider for a specific audio bus.
func connect_slider_to_bus(bus_index: int) -> void:
	# Get the name of the bus to use as a label.
	var bus_name: String = AudioServer.get_bus_name(bus_index)
	
	# Create the UI elements.
	var slider: HSlider = create_slider(bus_name)

	# --- Configure the slider ---
	# Sliders work best with a linear 0.0 to 1.0 range.
	slider.min_value = 0.0
	slider.max_value = db_to_linear(6.0)
	slider.step = 0.01 # Allows for fine-grained control.

	# --- Set the slider's initial value ---
	# Audio buses use decibels (dB), so we must convert it to a linear value for the slider.
	var current_db: float = AudioServer.get_bus_volume_db(bus_index)
	slider.value = db_to_linear(current_db) # Convert dB to a 0.0-1.0 value.

	# --- Connect the slider's signal to the function that changes the volume ---
	# When the slider's value changes, the `change_audio_volume` function will be called.
	# We use `bind(bus_index)` to pass the bus number to the function.
	slider.value_changed.connect(change_audio_volume.bind(bus_index))

# Creates the necessary UI nodes (Label, Slider) and adds them to the scene.
func create_slider(slider_name: String) -> HSlider:
	var slider: HSlider = HSlider.new()
	var vbox: VBoxContainer = VBoxContainer.new()
	var name_label: Label = Label.new()
	
	name_label.text = slider_name.capitalize()
	
	vbox_sounds.add_child(vbox)
	vbox.add_child(name_label)
	vbox.add_child(slider)
	
	return slider

# This function is called by the slider's `value_changed` signal.
func change_audio_volume(new_linear_value: float, bus_index: int) -> void:
	# A linear value of 0 is equivalent to negative infinity dB.
	# Godot clamps this to -80 dB, effectively silencing it.
	if new_linear_value == 0.0:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		# Convert the slider's 0.0-1.0 value back to decibels.
		var new_db_value: float = linear_to_db(new_linear_value)
		AudioServer.set_bus_volume_db(bus_index, new_db_value)
