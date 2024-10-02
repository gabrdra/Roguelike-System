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
	var conns := []
	while not passages_names.is_empty():
		var index = random.randi_range(0,passages_names.size()-1)
		var passage_name := passages_names[index]
		passages_names.remove_at(index)
		conns.append(Connection.new(room, passage_name))
	return conns

func _check_level_validity(used_rooms:Dictionary, input_rooms:Dictionary, required_rooms_names:Array[String]) -> bool:
	#if the required_room exists in used_rooms, use it from there, if it doesn't, use it from input_rooms
	#for every required_room and used_room check if for their unused passages there is still a possibility of reaching a room
	#if it doesn't return false
	#Required_rooms
	for room_name in required_rooms_names:
		if used_rooms.has(room_name):
			continue #will check in the used_rooms loop
		var room:Room = input_rooms[room_name]
		for passage_name in room.passages:
			if room.passages[passage_name]==null:
				var possible_connections:Array[Connection] = input_rooms[room_name].passages[passage_name].filter(
					func (c:Connection):
						if used_rooms.has(c.room.name):
							return used_rooms[c.room.name].room.passages[c.connected_passage] == null
						return true
				)
				if possible_connections.size() == 0:
					return false
		#Used_rooms
	for room_name in used_rooms:
		var room:Room = used_rooms[room_name].room
		for passage_name in room.passages:
			if room.passages[passage_name]==null:
				var possible_connections:Array[Connection] = input_rooms[room_name].passages[passage_name].filter(
					func (c:Connection):
						if used_rooms.has(c.room.name):
							return used_rooms[c.room.name].room.passages[c.connected_passage] == null
						return true
				)
				var possible_connections_after_filter_attempts:Array[Connection] = possible_connections.filter(
					func (c:Connection):
						return used_rooms[room_name].passages_attempts[passage_name].has(c.to_string())
				)
				if possible_connections.size() == 0:
					return false
	return true

func _remove_rooms_from_used_rooms(used_rooms:Dictionary, initial_room_to_erase:BacktrackData,
	connections_order:Array[Connection],unused_connections:Array[Connection]) -> void:
	var rooms_to_erase_array:=[]#works as a stack
	var erased_rooms:={}#works as a set
	#have an array that stores all the rooms to be removed, it erases the connections it has, add it's children to the list and then erases the room from used_rooms
	#after erasing all the necessary rooms, filter both the connections_order and the unused_connections arrays to contains only rooms that are still in used_rooms
	#but use the erased_rooms dictionary for that as it most likely will have fewer elements and as such a smaller look up time.
	rooms_to_erase_array.append(initial_room_to_erase)
	while not rooms_to_erase_array.is_empty():
		var room_to_erase:BacktrackData = rooms_to_erase_array.pop_back()
		# if erased_rooms.has(room_to_erase.room.name):
		# 	continue
		erased_rooms[room_to_erase.room.name] = true
		for connection_name in room_to_erase.room.passages:
			var connection:Connection = room_to_erase.room.passages[connection_name]
			if connection == null:
				continue
			if used_rooms[connection.room.name].parent_room_name != room_to_erase.room.name:
				used_rooms[connection.room.name].room.passages[connection.connected_passage] = null
				continue
			var child_room:BacktrackData = used_rooms[connection.room.name]
			# if not erased_rooms.has(child_room.room.name):
			rooms_to_erase_array.append(child_room)
		used_rooms.erase(room_to_erase.room.name)
	#filter connections_order
	connections_order = connections_order.filter(
		func (c:Connection):
			return !erased_rooms.has(c.room.name)
	)
	#filter unused_connections
	unused_connections = unused_connections.filter(
		func (c:Connection):
			return !erased_rooms.has(c.room.name)
	)

func generate_level(input_level:LevelData, input_seed:int = 0) -> LevelData:
	random = RandomNumberGenerator.new()
	if input_seed!=0:
		random.seed = input_seed
	var input_rooms:Dictionary = input_level.rooms
	var used_rooms:= {}
	var required_rooms_names:Array[String] = []
	var connections_order:Array[Connection] = []
	for room_name:String in input_rooms:
		if input_rooms[room_name].required:
			required_rooms_names.append(room_name)
	used_rooms[input_level.starter_room.name] = BacktrackData.new("",_create_used_room(input_level.starter_room))
	used_rooms[input_level.starter_room.name].passages_attempts = _get_passages_for_room(used_rooms[input_level.starter_room.name].room, {})
	var unused_connections = _get_unused_connections_from_room(used_rooms[input_level.starter_room.name].room)
	while !unused_connections.is_empty():
		if unused_connections.is_empty():
			break
		var outgoing_connection:Connection = unused_connections.pop_back()
		connections_order.append(outgoing_connection)
		if outgoing_connection.room.passages[outgoing_connection.connected_passage]!=null:
			#this connection was already used
			continue
		var possible_connections:Array[Connection] = input_rooms[outgoing_connection.room.name].passages[outgoing_connection.connected_passage].filter(
			func (c:Connection):
				#a connection is only possible the other side is not already being used
				if used_rooms.has(c.room.name):
					return used_rooms[c.room.name].room.passages[c.connected_passage] == null
				return true
		)
		if possible_connections.size() == 0:
			#there was no correspondent to the outgoing_connection, 
			#meaning a invalid state was created, in order to correct it, it's necessary to remove the current room, and it's children
			#also necessary to remove all the connections from the rooms that are being removed
			_remove_rooms_from_used_rooms(used_rooms, used_rooms[outgoing_connection.room.name], connections_order, unused_connections)
		var incomming_connection:Connection = _choose_random_element_array(possible_connections)
		used_rooms[outgoing_connection.room.name].passages_attempts[outgoing_connection.connected_passage][incomming_connection.to_string()] = incomming_connection
		if !used_rooms.has(incomming_connection.room.name):
			#if a room isn't on used_rooms yet it should be inserted
			# and it's passages added to the unused_connections
			var new_used_room:Room = _create_used_room(incomming_connection.room)
			used_rooms[new_used_room.name] = BacktrackData.new(outgoing_connection.room.name,new_used_room)
			used_rooms[new_used_room.name].passages_attempts = _get_passages_for_room(new_used_room, {})
			new_used_room.passages[incomming_connection.connected_passage] = outgoing_connection
			outgoing_connection.room.passages[outgoing_connection.connected_passage] = Connection.new(new_used_room, incomming_connection.connected_passage)
			unused_connections.append_array(_get_unused_connections_from_room(new_used_room))
		else:
			incomming_connection.room.passages[incomming_connection.connected_passage] = outgoing_connection
			outgoing_connection.room.passages[outgoing_connection.connected_passage] = incomming_connection
		#check validity and roll back if necessary
		if !_check_level_validity(used_rooms, input_rooms, required_rooms_names):
			var latest_connection:Connection = connections_order.pop_back()
			unused_connections.append(latest_connection)
			#check if the room that was just connected has another connection then the one that was just removed
			#and if it doesn't, remove the room from used_rooms
			var outgoing_connection_room = used_rooms[latest_connection.room.name]
			outgoing_connection_room.room.passages[latest_connection.connected_passage] = null
			var incomming_connection_room = used_rooms[outgoing_connection_room.room.passages[latest_connection.connected_passage].room.name]
			var had_more_connections = false
			for passages_names in incomming_connection_room:
				if passages_names == incomming_connection.connected_passage:
					continue
				if incomming_connection_room.room.passages[passages_names] != null:
					had_more_connections = true
					break
			if !had_more_connections:
				used_rooms.erase(incomming_connection_room.room.name)
	if used_rooms.is_empty():
		return LevelData.new() #couldn't generate a valid level
	var return_level := LevelData.new()
	var used_rooms_return := {}
	for name in used_rooms:
		used_rooms_return[name]=used_rooms[name].room
	return_level.rooms = used_rooms_return
	return_level.starter_room = used_rooms_return[input_level.starter_room.name]
	return return_level


class BacktrackData:
	var parent_room_name:String #room that inserted this room into the map
	var room:Room
	var passages_attempts:Dictionary
	func _init(_parent_room_name:String, _room:Room, _passages_attempts:Dictionary = {}) -> void:
		parent_room_name = _parent_room_name
		room = _room
		passages_attempts = _passages_attempts
