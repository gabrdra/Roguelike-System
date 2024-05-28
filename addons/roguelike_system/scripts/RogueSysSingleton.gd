@tool
class_name RogueSysSingleton extends Node

var maps: Dictionary = {}
var current_map_name:String
var current_map:MapData

func _init() -> void:
	if maps.size()==0:
		current_map_name = "first map"
		maps[current_map_name]=MapData.new()
	current_map=maps[current_map_name]

func get_rooms()->Dictionary:
	return current_map.rooms
	
func add_new_room(room:Room)-> void:
	current_map.rooms[room.name]=room
	
func get_room_by_name(name:String) -> Room:
	if(current_map.rooms.has(name)):
		return current_map.rooms[name]
	return null
	
func update_room(room:Room, old_room_name:String)->void:
	if room.name==old_room_name:
		current_map.rooms[room.name]=room
	else:
		current_map.rooms.erase(old_room_name)
		current_map.rooms[room.name]=room
func delete_room(room_name):
	current_map.rooms.erase(room_name)
	

class MapData:
	var rooms:Dictionary = {}#Room name will be key and the room will be the value
	var default_room_folder:String#add the option on settings to register a default folder for the rooms
	
