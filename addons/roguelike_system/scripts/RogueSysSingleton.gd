@tool
class_name RogueSysSingleton extends Node

signal throw_error

const user_settings_path := "user://roguesysplugin_user_settings.res"
var user_settings := UserRogueSysSettings.new()

var levels: Dictionary = {}
var current_level:LevelData
var current_level_name:String
var passages_holder_name:="Passages"

func _init() -> void:
	if levels.size()==0:
		create_new_level("Level 1")

func load_user_settings() -> void:
	if ResourceLoader.exists(user_settings_path):
		user_settings = ResourceLoader.load(user_settings_path)
	else:
		ResourceSaver.save(user_settings, user_settings_path)

func save_user_settings() -> void:
	ResourceSaver.save(user_settings, user_settings_path)

func get_show_errors() -> bool:
	return user_settings.show_errors
	
func set_show_errors(value: bool) -> void:
	user_settings.show_errors = value

func get_current_map_path() -> String:
	return user_settings.current_map_path

func set_current_map_path(path:String) -> void:
	user_settings.current_map_path = path

func create_new_map(path:String) -> void:
	levels = {}
	create_new_level("Level 1")
	set_current_map_path(path)
	SaveLoadData.save_plugin_data(get_current_map_path())

func get_rooms()->Dictionary:
	return current_level.rooms

func get_room_by_name(name:String) -> Room:
	if(current_level.rooms.has(name)):
		return current_level.rooms[name]
	return null

func add_new_room(room:Room, connections_to_add:Dictionary = {})-> void:
	current_level.rooms[room.name]=room
	_add_passages(room, connections_to_add)
	
func update_room(room:Room, old_room_name:String,
	connections_to_add:Dictionary = {},
	connections_to_remove:Dictionary = {})->void:
	if room.name==old_room_name:
		current_level.rooms[room.name]=room
	else:
		current_level.rooms.erase(old_room_name)
		current_level.rooms[room.name]=room
	_add_passages(room,connections_to_add)
	_remove_passages(room, connections_to_remove)

func delete_room(room:Room) -> void:
	_remove_passages(room, room.passages)
	current_level.rooms.erase(room.name)
	
func set_starter_room(room:Room) -> void:
	current_level.starter_room = room

func get_starter_room() -> Room:
	return current_level.starter_room

func create_new_level(level_name:String) -> void:
	if(levels.has(level_name)):
		printerr("A level with name "+level_name+" already exists!")
		return
	levels[level_name]=LevelData.new()
	set_current_level(level_name)

func rename_current_level(new_level_name:String)->void:
	levels[new_level_name]=current_level
	levels.erase(current_level_name)
	current_level_name=new_level_name
	
func delete_current_level():
	if(levels.size()==1):
		levels.clear()
		create_new_level("Level 1")
		return
	levels.erase(current_level_name)
	set_current_level(levels.keys()[0])

func set_current_level(level_name:String) -> void:
	if(!levels.has(level_name)):
		printerr("A level with the name of "+level_name+" doesn't exist!")
	current_level=levels[level_name]
	current_level_name=level_name

func _add_passages(room:Room, connections_to_add: Dictionary) -> void:
	for passage_name in connections_to_add:
		var connections: Array = connections_to_add[passage_name]
		room.passages[passage_name].append_array(connections)
		for connection in connections:
			var other_end_connection = Connection.new(room,passage_name)
			connection.room.passages[connection.connected_passage].append(other_end_connection)
			
func _remove_passages(room:Room, connections_to_remove: Dictionary) -> void:
	#TODO?: A doubly linked list instead of arrays would improve complexity on removal of connection
	for passage_name in connections_to_remove:
		var connections: Array = connections_to_remove[passage_name]
		var remaining_room_connections:Array = room.passages[passage_name].filter(
			func(c): 
				for conn in connections:
					if conn.equals(c):
						return false
				return true
		)
		room.passages[passage_name] = remaining_room_connections
		for connection in connections:
			var other_end_connection = _get_connection_from_array(
				connection.room.passages[connection.connected_passage],
				Connection.new(room, passage_name)
				)
			connection.room.passages[connection.connected_passage].erase(other_end_connection)
	

func _get_connection_from_array(arr: Array, connection_to_find: Connection) -> Connection:
	for conn in arr:
		if conn.equals(connection_to_find):
			return conn
	return null
