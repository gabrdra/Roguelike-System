@tool
extends MarginContainer

@onready var current_level_button: OptionButton = $VBoxContainer/CurrentLevelHolder/CurrentLevelButton
@onready var starter_room_button: OptionButton = $VBoxContainer/StarterRoomHolder/StarterRoomButton

var levels_names: Array[String]
var current_level_required_rooms_names: Array[String]

func fill_levels_manager_fields() -> void:
	print("fill_levels_manager_fields")
	levels_names.clear()
	current_level_button.clear()
	for level_name in RogueSys.levels:
		current_level_button.add_item(level_name)
		levels_names.append(level_name)
		if(level_name==RogueSys.current_level_name):
			current_level_button.select(levels_names.size()-1)
	
	current_level_required_rooms_names.clear()
	starter_room_button.clear()
	var rooms := RogueSys.get_rooms()
	var current_starter_room := RogueSys.get_starter_room()
	for room_name in rooms:
		var curr_room: Room = rooms[room_name]
		if(!curr_room.required):
			continue
		starter_room_button.add_item(room_name)
		current_level_required_rooms_names.append(room_name)
		if(current_starter_room == null):
			continue
		if(current_starter_room.name == room_name):
			current_level_button.select(current_level_required_rooms_names.size()-1)


func _on_visibility_changed() -> void:
	fill_levels_manager_fields()
