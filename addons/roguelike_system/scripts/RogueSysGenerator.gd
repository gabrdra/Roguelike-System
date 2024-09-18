class_name RogueSysGenerator extends Node

var random: RandomNumberGenerator

#For now, max_passes will be ignored and every room will be considered as having it set to 1

func _create_used_room(room:Room)->Room:
	var used_room := Room.new()
	used_room.name = room.name
	used_room.scene_uid = room.scene_uid
	for passage_name in room.passages:
		used_room.passages[passage_name]=null
	return used_room

func _choose_random_element_array(array:Array):
	return array[random.randi_range(0,array.size()-1)]

func _get_unused_connections_from_room(room:Room) -> SimpleQueue:
	var passages_names:Array[String]
	for passage_name in room.passages:
		if room.passages[passage_name]==null:
			passages_names.append(passage_name)
	var queue = SimpleQueue.new()
	while not passages_names.is_empty():
		var index = random.randi_range(0,passages_names.size()-1)
		var passage_name := passages_names[index]
		passages_names.remove_at(index)
		queue.insert(Connection.new(room, passage_name))
	return queue
	
func generate_level(input_level:LevelData, input_seed:int = 0, attempts:int = 1000000) -> LevelData:
	random = RandomNumberGenerator.new()
	for i in range(attempts):
		var input_rooms:Dictionary = input_level.rooms
		var used_rooms:= {}
		used_rooms[input_level.starter_room.name] = _create_used_room(input_level.starter_room)
		var queue = _get_unused_connections_from_room(used_rooms[input_level.starter_room.name])
		var successful := true
		while successful:
			if queue.is_empty():
				break
			var outgoing_connection:Connection = queue.pop_front()
			if outgoing_connection.room.passages[outgoing_connection.connected_passage]!=null:
				#this connection was already used
				continue
			var possible_connections:Array[Connection] = input_rooms[outgoing_connection.room.name].passages[outgoing_connection.connected_passage].filter(
				func (c:Connection):
					#a connection is only possible the other side is not already being used
					if used_rooms.has(c.room.name):
						return used_rooms[c.room.name].passages[c.connected_passage] == null
					return true
			)
			if possible_connections.size() == 0:
				#there was no correspondent to the outgoing_connection, 
				#meaning a invalid state was created aborts generation and tries again
				successful = false
				break
			var incomming_connection:Connection = _choose_random_element_array(possible_connections)
			if not used_rooms.has(incomming_connection.room.name):
				#if a room isn't on used_rooms yet it should be inserted
				# and it's passages added to the queue
				var new_used_room:Room = _create_used_room(incomming_connection.room)
				used_rooms[new_used_room.name] = new_used_room
				new_used_room.passages[incomming_connection.connected_passage] = outgoing_connection
				outgoing_connection.room.passages[outgoing_connection.connected_passage] = Connection.new(new_used_room, incomming_connection.connected_passage)
				queue.insert_queue(_get_unused_connections_from_room(new_used_room))
			else:
				incomming_connection.room.passages[incomming_connection.connected_passage] = outgoing_connection
				outgoing_connection.room.passages[outgoing_connection.connected_passage] = incomming_connection
		if successful:
			var return_level = LevelData.new()
			return_level.rooms = used_rooms
			return_level.starter_room = used_rooms[input_level.starter_room.name]
			return return_level
	return LevelData.new()
