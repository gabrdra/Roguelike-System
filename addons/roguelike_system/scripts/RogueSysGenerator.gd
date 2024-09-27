class_name RogueSysGenerator extends Node

var random: RandomNumberGenerator

#For now, max_passes will be ignored and every room will be considered as having it set to 1


func _get_passages_for_room(room:Room, default_value = null) -> Dictionary:
	var passages := {}
	for passage_name in room.passages:
		passages[passage_name]=default_value
	return passages

func _create_used_room(room:Room)->Room:
	var used_room := Room.new()
	used_room.name = room.name
	used_room.scene_uid = room.scene_uid
	used_room.passages = _get_passages_for_room(room)
	#for passage_name in room.passages:
		#used_room.passages[passage_name]=null
	return used_room

func _choose_random_element_array(array:Array):
	return array[random.randi_range(0,array.size()-1)]

func _get_unused_connections_from_room(room:Room) -> Array:
	var passages_names:Array[String]
	for passage_name in room.passages:
		if room.passages[passage_name]==null:
			passages_names.append(passage_name)
	var stack := []
	while not passages_names.is_empty():
		var index = random.randi_range(0,passages_names.size()-1)
		var passage_name := passages_names[index]
		passages_names.remove_at(index)
		stack.append(Connection.new(room, passage_name))
	return stack

#func _backtrack()

func generate_level(input_level:LevelData, input_seed:int = 0) -> LevelData:
	random = RandomNumberGenerator.new()
	var input_rooms:Dictionary = input_level.rooms
	var used_rooms_backtrack:= {}
	used_rooms_backtrack[input_level.starter_room.name] = BacktrackData.new("",_create_used_room(input_level.starter_room))
	used_rooms_backtrack[input_level.starter_room.name].passages_attempts = _get_passages_for_room(used_rooms_backtrack[input_level.starter_room.name].room, [])
	var stack = _get_unused_connections_from_room(used_rooms_backtrack[input_level.starter_room.name].room)
	var successful := true
	while successful:
		if stack.is_empty():
			break
		var outgoing_connection:Connection = stack.pop_back()
		if outgoing_connection.room.passages[outgoing_connection.connected_passage]!=null:
			#this connection was already used
			continue
		var possible_connections:Array[Connection] = input_rooms[outgoing_connection.room.name].passages[outgoing_connection.connected_passage].filter(
			func (c:Connection):
				#a connection is only possible the other side is not already being used
				if used_rooms_backtrack.has(c.room.name):
					return used_rooms_backtrack[c.room.name].room.passages[c.connected_passage] == null
				return true
		)
		if possible_connections.size() == 0:
			#there was no correspondent to the outgoing_connection, 
			#meaning a invalid state was created aborts generation and tries again
			successful = false
			break
		var incomming_connection:Connection = _choose_random_element_array(possible_connections)
		used_rooms_backtrack[outgoing_connection.room.name].passages_attempts[outgoing_connection.connected_passage].append(incomming_connection)
		if not used_rooms_backtrack.has(incomming_connection.room.name):
			#if a room isn't on used_rooms_backtrack yet it should be inserted
			# and it's passages added to the stack
			var new_used_room:Room = _create_used_room(incomming_connection.room)
			used_rooms_backtrack[new_used_room.name] = BacktrackData.new(outgoing_connection.room.name,new_used_room)
			used_rooms_backtrack[new_used_room.name].passages_attempts = _get_passages_for_room(new_used_room, [])
			new_used_room.passages[incomming_connection.connected_passage] = outgoing_connection
			outgoing_connection.room.passages[outgoing_connection.connected_passage] = Connection.new(new_used_room, incomming_connection.connected_passage)
			stack.append_array(_get_unused_connections_from_room(new_used_room))
		else:
			incomming_connection.room.passages[incomming_connection.connected_passage] = outgoing_connection
			outgoing_connection.room.passages[outgoing_connection.connected_passage] = incomming_connection
	if successful:
		var return_level := LevelData.new()
		var used_rooms := {}
		for name in used_rooms_backtrack:
			used_rooms[name]=used_rooms_backtrack[name].room
		return_level.rooms = used_rooms
		return_level.starter_room = used_rooms[input_level.starter_room.name]
		return return_level
	return LevelData.new()


class BacktrackData:
	var parent_room_name:String #room that inserted this room into the map
	var room:Room
	var passages_attempts:Dictionary
	var connections_array:Array[Connection] #A duplicate of the array at that point in time, necessary in order to reconstruct the state of the map in case of a inconsistency that triggers the backtrack
	func _init(_parent_room_name:String, _room:Room, _passages_attempts:Dictionary = {}, _connections_array:Array[Connection] = []):
		parent_room_name = _parent_room_name
		room = _room
		passages_attempts = _passages_attempts
		connections_array = _connections_array
