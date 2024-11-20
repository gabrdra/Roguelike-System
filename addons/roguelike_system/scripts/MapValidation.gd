@tool
class_name MapValidation extends Node

#static func _print_visited_rooms(visited_rooms:Dictionary) -> void:
	##Debugging function
	#for r_name in visited_rooms:
		#var c:String = visited_rooms[r_name]
		#print("r: "+ r_name+" c: "+c)

static func validate_map(map_data:MapData) -> MapData:
	var still_valid:=true
	var validated_levels := {}
	var duplicated_map_data := map_data.duplicate_map_data()
	for level_name:String in duplicated_map_data.levels:
		var level:LevelData = duplicated_map_data.levels[level_name]
		if level.starter_room == null:
			var message:= "The "+level_name+" has no starter room"
			printerr(message)
			RogueSys.throw_error.emit(message)
			return null
		var validated_level := _validate_level(level, duplicated_map_data.passages_holder_name)
		if validated_level == null:
			var message:= "The "+level_name+" couldn't generate at least one viable instance"
			printerr(message)
			RogueSys.throw_error.emit(message)
			return null
		validated_levels[level_name]=validated_level
	return MapData.new(validated_levels, duplicated_map_data.passages_holder_name)

static func _multiply_rooms(level:LevelData) -> void:
	#This method is necessary in order to repeat the rooms where max_passes is > 1
	for origin_room_name in level.rooms:
		var origin_room:Room = level.rooms[origin_room_name]
		if origin_room.max_passes == 1:
			continue
		for i in range(origin_room.max_passes-1):
			var new_room:Room = Room.new(
				origin_room.name+"_"+str(i+2),
				origin_room.scene_uid,
				origin_room.required,
				1
			)
			level.rooms[new_room.name] = new_room
			for passage_name in origin_room.passages:
				var origin_room_conns:Array = origin_room.passages[passage_name]
				var duplicated_connections:Array[Connection] = []
				for origin_conn:Connection in origin_room_conns:
					duplicated_connections.append(
						Connection.new(
							level.rooms[origin_conn.room.name], origin_conn.connected_passage
						)
					)
					level.rooms[origin_conn.room.name].passages[origin_conn.connected_passage].append(Connection.new(new_room, passage_name))
				new_room.passages[passage_name]=duplicated_connections
		origin_room.max_passes = 1

static func _validate_level(level:LevelData, passages_holder_name:String) -> ValidatedLevelData:
	var still_valid:=true
	var required_rooms_names:Array[String] = []
	for room_name:String in level.rooms:
		var room:Room = level.rooms[room_name]
		if room.required:
			required_rooms_names.append(room.name)
		still_valid = still_valid and _validate_room(room, passages_holder_name)
		if !still_valid:
			return null
	return _generate_level_possibilities(level)

static func _generate_level_possibilities(input_level:LevelData) -> ValidatedLevelData:
	_multiply_rooms(input_level)
	var input_rooms:Dictionary = input_level.rooms
	var validated_level = ValidatedLevelData.new(input_level.rooms, input_level.starter_room)
	var connections_pair_indexes:={}
	var used_rooms:= {}
	var required_rooms_names:Array[String] = []
	var connections_order:Array[Connection] = []
	for room_name:String in input_rooms:
		if input_rooms[room_name].required:
			required_rooms_names.append(room_name)
	used_rooms[input_level.starter_room.name] = BacktrackData.new("",_create_used_room(input_level.starter_room))
	var starter_room:BacktrackData = used_rooms[input_level.starter_room.name]
	starter_room.passages_attempts = _get_passages_for_room(starter_room.room, {})
	
	var level_is_valid:=false
	var unused_connections = _get_unused_connections_from_room(starter_room.room)
	while true:
		level_is_valid=false
		while !unused_connections.is_empty():
			var outgoing_connection:Connection = unused_connections.pop_back()
			connections_order.append(outgoing_connection)
			if outgoing_connection.room.passages[outgoing_connection.connected_passage]!=null:
				#this connection was already used
				continue
			var possible_connections:Array[Connection] = input_rooms[outgoing_connection.room.name].passages[outgoing_connection.connected_passage].filter(
				func (c:Connection):
					#a connection is only possible the other side is not already being used
					#missing filter by attempt as well
					var valid_room := true
					if used_rooms.has(c.room.name):
						valid_room = used_rooms[c.room.name].room.passages[c.connected_passage] == null
					valid_room = !used_rooms[outgoing_connection.room.name].passages_attempts[outgoing_connection.connected_passage].has(c.to_string()) and valid_room
					return valid_room
			)
			if possible_connections.size() == 0:
				#there was no correspondent to the outgoing_connection, 
				#meaning a invalid state was created, in order to correct it, it's necessary to remove the current room, and it's children
				#also necessary to remove all the connections from the rooms that are being removed
				_remove_rooms_from_used_rooms(used_rooms, used_rooms[outgoing_connection.room.name], connections_order)
				unused_connections = _recreate_unused_connections(starter_room, used_rooms)
				connections_order = connections_order.filter(
					func (c:Connection):
						if used_rooms.has(c.room.name):
							return used_rooms[(c.room.name)].room.passages[c.connected_passage]!=null
				)
				continue
			var incomming_connection:Connection = possible_connections.pop_back()
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
				#If the room in incomming_connection is used as is then the room that would be altered is the one in input_rooms instead of the one in used_rooms
				used_rooms[incomming_connection.room.name].room.passages[incomming_connection.connected_passage] = outgoing_connection
				outgoing_connection.room.passages[outgoing_connection.connected_passage] = incomming_connection
			#check validity and roll back if necessary
			level_is_valid = _check_level_validity(starter_room, used_rooms, input_rooms, required_rooms_names.size())
			if !level_is_valid:
				var latest_connection:Connection = connections_order.pop_back()
				unused_connections.append(latest_connection)
				#check if the room that was just connected has another connection then the one that was just removed
				#and if it doesn't, remove the room from used_rooms
				var outgoing_connection_room:BacktrackData = used_rooms[latest_connection.room.name]
				var incomming_connection_room:BacktrackData = used_rooms[outgoing_connection_room.room.passages[latest_connection.connected_passage].room.name]
				outgoing_connection_room.room.passages[latest_connection.connected_passage] = null
				var had_more_connections = false
				for passages_names in incomming_connection_room.room.passages:
					if passages_names == incomming_connection.connected_passage:
						continue
					if incomming_connection_room.room.passages[passages_names] != null:
						had_more_connections = true
						break
				if !had_more_connections:
					unused_connections = unused_connections.filter(
						func (c:Connection):
							return c.room.name != incomming_connection_room.room.name
					)
					used_rooms.erase(incomming_connection_room.room.name)
		if connections_order.is_empty() or !level_is_valid:
			break
		var possibility:Array[int] = []
		for conn in connections_order:
			var other_side_conn = used_rooms[conn.room.name].room.passages[conn.connected_passage]
			var conn_pair = ConnectionPair.new(conn, other_side_conn)
			var index = -1
			if connections_pair_indexes.has(conn_pair.to_string()):
				index = connections_pair_indexes[conn_pair.to_string()]
			if index == -1 and connections_pair_indexes.has(conn_pair.inverted_to_string()):
				index = connections_pair_indexes[conn_pair.inverted_to_string()]
			if index == -1:
				connections_pair_indexes[conn_pair.to_string()] = validated_level.connectionPairs.size()
				index = validated_level.connectionPairs.size()
				validated_level.connectionPairs.append(conn_pair)
			possibility.append(index)
		validated_level.possibilities.append(possibility)
		
		var incomming_connection = used_rooms[connections_order.back().room.name].room.passages[connections_order.back().connected_passage]
		var latest_connection:Connection = connections_order.pop_back()
		unused_connections.append(latest_connection)
		#check if the room that was just connected has another connection then the one that was just removed
		#and if it doesn't, remove the room from used_rooms
		var outgoing_connection_room:BacktrackData = used_rooms[latest_connection.room.name]
		var incomming_connection_room:BacktrackData = used_rooms[outgoing_connection_room.room.passages[latest_connection.connected_passage].room.name]
		outgoing_connection_room.room.passages[latest_connection.connected_passage] = null
		var had_more_connections = false
		for passages_names in incomming_connection_room.room.passages:
			if passages_names == incomming_connection.connected_passage:
				continue
			if incomming_connection_room.room.passages[passages_names] != null:
				had_more_connections = true
				break
		if !had_more_connections:
			unused_connections = unused_connections.filter(
				func (c:Connection):
					return c.room.name != incomming_connection_room.room.name
			)
			used_rooms.erase(incomming_connection_room.room.name)
	if validated_level.possibilities.is_empty():
		return null
	return validated_level

static func _get_unused_connections_from_room(room:Room) -> Array:
	var passages_names:Array[String]
	for passage_name in room.passages:
		if room.passages[passage_name]==null:
			passages_names.append(passage_name)
	var conns := []
	for passage_name in passages_names:
		conns.append(Connection.new(room, passage_name))
	return conns

static func _create_used_room(room:Room)->Room:
	var used_room := Room.new()
	used_room.name = room.name
	used_room.scene_uid = room.scene_uid
	used_room.passages = _get_passages_for_room(room)
	return used_room

static func _get_passages_for_room(room:Room, default_value = null) -> Dictionary:
	var passages := {}
	for passage_name in room.passages:
		passages[passage_name]=default_value
	return passages

static func _remove_rooms_from_used_rooms(used_rooms:Dictionary, initial_room_to_erase:BacktrackData,
	connections_order:Array) -> void:
	var rooms_to_erase_array:=[]#works as a stack
	var erased_rooms:={}#works as a set
	rooms_to_erase_array.append(initial_room_to_erase)
	while not rooms_to_erase_array.is_empty():
		var room_to_erase:BacktrackData = rooms_to_erase_array.pop_back()
		if erased_rooms.has(room_to_erase.room.name):
			continue
		erased_rooms[room_to_erase.room.name] = true
		for connection_name in room_to_erase.room.passages:
			var connection:Connection = room_to_erase.room.passages[connection_name]
			if connection == null:
				continue
			used_rooms[connection.room.name].room.passages[connection.connected_passage] = null
			if used_rooms[connection.room.name].parent_room_name != room_to_erase.room.name:
				continue
			var child_room:BacktrackData = used_rooms[connection.room.name]
			rooms_to_erase_array.append(child_room)
		used_rooms.erase(room_to_erase.room.name)
	connections_order = connections_order.filter(
		func (c:Connection):
			return !erased_rooms.has(c.room.name)
	)
static func _recreate_unused_connections(starter_room:BacktrackData, used_rooms:Dictionary) -> Array[Connection]:
	if used_rooms.size() == 0:
		return []
	var unused_connections:Array[Connection] = []
	var stack:Array[Connection] = []
	var visited:Dictionary={}
	for passage_name:String in starter_room.room.passages:
		var conn:Connection = starter_room.room.passages[passage_name]
		if conn == null:
			unused_connections.append(Connection.new(starter_room.room, passage_name))
		else:
			stack.append(conn)
	visited[starter_room.room.name]=true
	while !stack.is_empty():
		var curr_conn:Connection=stack.pop_back()
		if visited.has(curr_conn.room.name):
			continue
		visited[curr_conn.room.name]=true
		var curr_room:BacktrackData = used_rooms[curr_conn.room.name]
		for passage_name:String in curr_room.room.passages:
			var conn:Connection = curr_room.room.passages[passage_name]
			if conn == null:
				unused_connections.append(Connection.new(curr_room.room, passage_name))
			else:
				stack.append(conn)
	return unused_connections
	
static func _check_level_validity(starter_room:BacktrackData, used_rooms:Dictionary, input_rooms:Dictionary, required_rooms_size:int) -> bool:
	var stack:Array[Connection]
	var rooms_visited:Dictionary #works as a set
	var required_rooms_found:Dictionary #works as a set
	required_rooms_found[starter_room.room.name]=true
	for passage_name in starter_room.room.passages:
		if(starter_room.room.passages[passage_name]!=null):
			stack.append(starter_room.room.passages[passage_name])
			continue
		stack.append_array(input_rooms[starter_room.room.name].passages[passage_name])
	rooms_visited[starter_room.room.name]=true
	while !stack.is_empty():
		var curr_conn := stack.pop_back()
		if rooms_visited.has(curr_conn.room.name):
			continue
		rooms_visited[curr_conn.room.name]=true
		if used_rooms.has(curr_conn.room.name):
			var curr_room_backtrack:BacktrackData = used_rooms[curr_conn.room.name]
			for passage_name in curr_room_backtrack.room.passages:
				var curr_passage = curr_room_backtrack.room.passages[passage_name]
				if(curr_passage!=null):
					stack.append(curr_passage)
				else:
					var possible_connections:Array[Connection] = input_rooms[curr_room_backtrack.room.name].passages[passage_name].filter(
					func (c:Connection):
						var valid_room := true
						if used_rooms.has(c.room.name):
							valid_room = used_rooms[c.room.name].room.passages[c.connected_passage] == null
						valid_room = !curr_room_backtrack.passages_attempts[passage_name].has(c.to_string()) and valid_room
						return valid_room
					)
					if possible_connections.size() == 0:
						return false #a room in the final level has 0 possible connections, meaning a inconsistent state
					stack.append_array(possible_connections)
		else:
				var curr_room:Room = input_rooms[curr_conn.room.name]
				for passage_name in curr_room.passages:
					stack.append_array(curr_room.passages[passage_name])
		if input_rooms[curr_conn.room.name].required:
			required_rooms_found[curr_conn.room.name]=true
	return required_rooms_found.size()==required_rooms_size

class BacktrackData:
	var parent_room_name:String #room that inserted this room into the map
	var room:Room
	var passages_attempts:Dictionary
	func _init(_parent_room_name:String, _room:Room, _passages_attempts:Dictionary = {}) -> void:
		parent_room_name = _parent_room_name
		room = _room
		passages_attempts = _passages_attempts

#static func _get_connection_from_array(arr: Array[Connection], connection_to_find: Connection) -> Connection:
	#for conn in arr:
		#if conn.equals(connection_to_find):
			#return conn
	#return null
	
static func _validate_room(room:Room, passages_holder_name:String) -> bool:
	var still_valid:=true
	#Check if the passages exist on the Room in the same way as in the scene
	var loaded_room := ResourceLoader.load(room.scene_uid)
	if !loaded_room:
		var message := "Map validation error: error loading "+room.name+" scene"
		printerr(message)
		return false
	var room_instance:Node = loaded_room.instantiate()
	if !room_instance:
		var message := "Map validation error: error instancing "+room.name+" scene"
		printerr(message)
		return false
	var passages_node:Node = room_instance.get_node_or_null(passages_holder_name)
	if(passages_node == null):
		var message := "Map validation error: room " + room.name +" lacks the node "+passages_holder_name
		printerr(message)
		still_valid = false
		return still_valid
	var passages_scene:Array[Node] = passages_node.get_children()
	var passages_found:=0
	for passage_scene:Node in passages_scene:
		if room.passages.has(passage_scene.name):
			passages_found+=1
		else:
			var message := "Map validation error: scene corresponding to room " + room.name +" has "+passage_scene.name+" while the room inside the plugin doesn't"
			printerr(message)
			still_valid = false
	if passages_found!=room.passages.size():
		#at least one passage that should exists in the scene, doesn't exist
		var message := "Map validation error: the room "+room.name+ " has "+str(room.passages.size()-passages_found)+" passage(s) more than it's corresponding scene"
		printerr(message)
		still_valid = false
	still_valid = still_valid and _validate_room_passages(room)
	return still_valid
	
static func _validate_room_passages(room:Room):
	#Check if all the passages have at least one connection
	var still_valid:=true
	for room_passage_name:String in room.passages:
		if room.passages[room_passage_name].size() != 0:
			continue
		still_valid = false
		break
	return still_valid
