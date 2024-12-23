@tool
extends MarginContainer

@onready var current_level_button: OptionButton = $VBoxContainer/CurrentLevelHolder/CurrentLevelButton
@onready var starter_room_button: OptionButton = $VBoxContainer/StarterRoomHolder/StarterRoomButton
@onready var create_rename_level_window: Window = $CreateRenameLevelWindow
@onready var delete_level_confirmation: ConfirmationDialog = $DeleteLevelConfirmation
@onready var create_rename_input: TextEdit = $CreateRenameLevelWindow/Background/VBoxContainer/CreateRenameInput
@onready var create_rename_confirm_button: Button = $CreateRenameLevelWindow/Background/VBoxContainer/HBoxContainer/CreateRenameConfirmButton
@onready var create_rename_warning_label: Label = $CreateRenameLevelWindow/Background/VBoxContainer/CreateRenameWarningLabel
@onready var export_map_file_dialog: FileDialog = $ExportMapFileDialog
@onready var minimum_rooms_input: SpinBox = $VBoxContainer/MinimumRoomsHolder/MinimumRoomsInput
@onready var maximum_rooms_input: SpinBox = $VBoxContainer/MaximumRoomsHolder/MaximumRoomsInput

var levels_names: Array[String]
var current_level_required_rooms: Array[Room]

enum Actions {DELETE,CREATE,RENAME}
var current_action:Actions

func fill_levels_manager_fields() -> void:
	_set_current_level_button()
	_set_starter_room_button()
	_set_minimum_rooms_input()
	_set_maximum_rooms_input()

func _set_current_level_button() -> void:
	levels_names.clear()
	current_level_button.clear()
	for level_name in RogueSys.map_data.levels:
		current_level_button.add_item(level_name)
		levels_names.append(level_name)
		if level_name==RogueSys.current_level_name:
			current_level_button.select(levels_names.size()-1)

func _set_starter_room_button() -> void:
	current_level_required_rooms.clear()
	starter_room_button.clear()
	var rooms := RogueSys.get_rooms()
	var current_starter_room := RogueSys.get_starter_room()
	for room_name in rooms:
		var curr_room: Room = rooms[room_name]
		if !curr_room.required:
			continue
		starter_room_button.add_item(room_name)
		current_level_required_rooms.append(curr_room)
		if current_starter_room == null:
			continue
		if current_starter_room.name == room_name:
			starter_room_button.select(current_level_required_rooms.size()-1)

func _set_minimum_rooms_input() -> void:
	minimum_rooms_input.value = RogueSys.current_level.min_rooms
	
func _set_maximum_rooms_input() -> void:
	maximum_rooms_input.value = RogueSys.current_level.max_rooms

func _on_visibility_changed() -> void:
	fill_levels_manager_fields()

func _on_create_new_level_button_button_down() -> void:
	current_action = Actions.CREATE
	create_rename_level_window.title = "New level"
	create_rename_warning_label.text = "Level name cannot be empty"
	create_rename_level_window.popup_centered()


func _on_rename_level_button_button_down() -> void:
	current_action = Actions.RENAME
	create_rename_level_window.title = "rename level"
	create_rename_warning_label.text = "The current level already has this name"
	create_rename_level_window.popup_centered()
	create_rename_input.text = RogueSys.current_level_name


func _on_delete_level_button_button_down() -> void:
	current_action = Actions.DELETE
	delete_level_confirmation.dialog_text = "Delete "+RogueSys.current_level_name+"?"
	delete_level_confirmation.popup_centered()


func _on_create_rename_level_window_close_requested() -> void:
	create_rename_input.text = ""
	create_rename_confirm_button.disabled = true
	create_rename_level_window.hide()

func _on_confirm_button_button_down() -> void:
	if current_action == Actions.CREATE:
		RogueSys.create_new_level(create_rename_input.text)
	elif current_action==Actions.RENAME:
		RogueSys.rename_current_level(create_rename_input.text)
	elif current_action==Actions.DELETE:
		RogueSys.delete_current_level()
	_on_create_rename_level_window_close_requested()
	fill_levels_manager_fields()


func _on_create_rename_input_text_changed() -> void:
	var new_text := create_rename_input.text
	if new_text.is_empty() :
		create_rename_confirm_button.disabled=true
		create_rename_warning_label.text = "Level name cannot be empty"
		
		return
	elif RogueSys.map_data.levels.has(new_text):
		if current_action==Actions.CREATE:
			create_rename_confirm_button.disabled=true
			create_rename_warning_label.text = "A new level cannot have the same name as a existing level"
			return
		elif current_action==Actions.RENAME:
			create_rename_confirm_button.disabled=true
			if RogueSys.current_level_name==new_text:
				create_rename_warning_label.text = "The current level already has this name"
			else:
				create_rename_warning_label.text = "Another level already has that name"
			return
	create_rename_warning_label.text = ""
	create_rename_confirm_button.disabled=false


func _on_current_level_button_item_selected(index: int) -> void:
	RogueSys.set_current_level(levels_names[index])
	_set_starter_room_button()

func _on_starter_room_button_item_selected(index: int) -> void:
	RogueSys.set_starter_room(current_level_required_rooms[index])

func _on_export_map_button_button_down() -> void:
	var validate_map = MapValidation.validate_map(RogueSys.map_data)
	if validate_map:
		print("Map validation successful, use the separate program to generate the instances!")
	#export_map_file_dialog.popup_centered_ratio(0.5)
	#var path = "res://demo_2D/export_data/map_data.json"
	#SaveLoadData.export_data(path)
	
#func _on_export_map_file_dialog_file_selected(path: String) -> void:
	#var validated_map := MapValidation.validate_map(RogueSys.map_data)
	#if validated_map == null:
		##await get_tree().create_timer(0.1).timeout
		#printerr("There were errors during map validation")
		#return
	#SaveLoadData.export_data(validated_map, path)


func _on_minimum_rooms_input_value_changed(value: float) -> void:
	RogueSys.current_level.min_rooms = value


func _on_maximum_rooms_input_value_changed(value: float) -> void:
	RogueSys.current_level.max_rooms = value
