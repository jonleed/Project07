# Attach this script to any node in your scene.
extends Node

const SAVE_PATH = "user://my_data.tres"

var loaded_data:Dictionary

func _ready():
	# 1. Try to load an existing dictionary first.
	loaded_data = load_dictionary()
	
	if not loaded_data.is_empty():
		print("✅ Found and loaded existing data: ", loaded_data)
		loaded_data.get_or_add("Started",true)
		save_dictionary(loaded_data) # Optional: re-save the modified data
	else:
		print("⚠️ No saved data found. Creating and saving a new dictionary.")
		# 2. If no data exists, create a new dictionary and save it.
		var new_dict = {}
		new_dict.get_or_add("Started",true)
		save_dictionary(new_dict)

	loaded_data = load_dictionary()

# --- Functions ---
func load_dictionary() -> Dictionary:
	# First, check if the file even exists.
	if not FileAccess.file_exists(SAVE_PATH):
		print("Load failed: File does not exist at ", SAVE_PATH)
		return {} # Return an empty dictionary to avoid errors.

	# Load the resource file from the path.
	var loaded_resource = ResourceLoader.load(SAVE_PATH)
	
	# Check if the loaded resource is the correct type.
	if loaded_resource is LogResource:
		return loaded_resource.data
	else:
		print("Load failed: File is not a valid DictionaryResource.")
		return {}

## Saves the given dictionary to the specified SAVE_PATH.
func save_dictionary(dict_to_save: Dictionary):
	var dict_resource = LogResource.new()
	dict_resource.data = dict_to_save
	var error = ResourceSaver.save(dict_resource, SAVE_PATH)
	
	if error == OK:
		print("Successfully saved resource to: ", SAVE_PATH)
	else:
		print("Error saving resource: ", error)

## Opens the saved resource file using the OS's default application.
func open_saved_file():
	if not FileAccess.file_exists(SAVE_PATH):
		print("File does not exist at path: ", SAVE_PATH)
		return

	var absolute_path = ProjectSettings.globalize_path(SAVE_PATH)
	OS.shell_open(absolute_path)
