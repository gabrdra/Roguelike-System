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

func get_room_by_name(name:String) -> Room:
	if(current_map.rooms.has(name)):
		return current_map.rooms[name]
	return null

func add_new_room(room:Room, connections_to_add:Dictionary = {})-> void:
	current_map.rooms[room.name]=room
	_add_passages(room, connections_to_add)
	
func update_room(room:Room, old_room_name:String,
	connections_to_add:Dictionary = {},
	connections_to_remove:Dictionary = {})->void:
	if room.name==old_room_name:
		current_map.rooms[room.name]=room
	else:
		current_map.rooms.erase(old_room_name)
		current_map.rooms[room.name]=room
	_add_passages(room,connections_to_add)
	_remove_passages(room, connections_to_remove)

func delete_room(room_name) -> void:
	current_map.rooms.erase(room_name)
	
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

class MapData:
	var rooms:Dictionary = {}#Room name will be key and the room will be the value
	var default_room_folder:String#add the option on settings to register a default folder for the rooms
	
