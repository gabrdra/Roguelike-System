@tool
class_name MapValidation extends Node

#static func _print_visited_rooms(visited_rooms:Dictionary) -> void:
	##Debugging function
	#for r_name in visited_rooms:
		#var c:String = visited_rooms[r_name]
		#print("r: "+ r_name+" c: "+c)

static func validate_map(map_data:MapData) -> MapData:
	var still_valid:=true
	for level_name:String in map_data.levels:
		var level:LevelData = map_data.levels[level_name]
		var required_rooms_names:Array[String] = []
		for room_name:String in level.rooms:
			var room:Room = level.rooms[room_name]
			if room.required:
				required_rooms_names.append(room.name)
			still_valid = still_valid and _validate_room(room, map_data.passages_holder_name)
			if !still_valid:
				return null
		#Check if there is an invalid connection
		#starting from each required room, check what other rooms are reachable
		#if a room is not reachable, remove it from the level
		#if a removed room was a required room it means that the level is impossible to be generated
		#repeat for each required room until no changes are made
		var keep_looping := true
		while keep_looping:
			keep_looping = false
			for required_room_name:String in required_rooms_names:
				var required_room:Room = level.rooms[required_room_name]
				var deque := SimpleDeque.new()
				var visited_rooms := {} 
				#visited_rooms has 2 uses, first it keeps the rooms that were already reached 
				#and second it keeps the name of the passage from where that room was reached
				visited_rooms[required_room_name]=""
				for passage_name:String in required_room.passages:
					var conns_passage:Array[Connection] = required_room.passages[passage_name]
					for conn in conns_passage:
						if visited_rooms.has(conn.room.name):
							continue
						deque.insert_back(conn.room)
						visited_rooms[conn.room.name] = conn.connected_passage
				#A slightly modified bfs search 
				while !deque.is_empty():
					var current_room:Room = deque.pop_front()
					for passage_name:String in current_room.passages:
						if passage_name == visited_rooms[current_room.name]:
							continue
						var conns_passage:Array[Connection] = current_room.passages[passage_name]
						for conn in conns_passage:
							if visited_rooms.has(conn.room.name):
								continue
							deque.insert_back(conn.room)
							visited_rooms[conn.room.name] = conn.connected_passage
				#compares all rooms with rooms current on visited_rooms, if they are equal do nothing
				#if they aren't equal, remove the room that wasn't visited and set keep_looping to true
				if level.rooms.size() == visited_rooms.size():
					continue
				var rooms_names_to_remove:Array = []
				for room_name:String in level.rooms.keys():
					if visited_rooms.has(room_name):
						continue
					if level.rooms[room_name].required:
						var message := "Map validation error: The required rooms "+room_name+ " and "+required_room_name+" are currently incompatible in terms of accessibility"
						printerr(message)
						still_valid = false
						keep_looping = false
						break
					var message:= "Map validation warning: Room removal alert - the room "+room_name+ " will be removed from the exported data as it would be unreachable due to the required room "+required_room_name
					printerr(message)
					rooms_names_to_remove.append(room_name)
					keep_looping = true
				if !still_valid:
					return null
				if !keep_looping:
					continue
				while !rooms_names_to_remove.is_empty():
					var room_name:String = rooms_names_to_remove.pop_back()
					#TODO?: after removing a room, remove it's neighboor if one of it's passages now has 0 connections
					var room_to_remove:Room = level.rooms[room_name]
					for passage_name:String in room_to_remove.passages:
						while !room_to_remove.passages[passage_name].is_empty():
							var conn_to_remove:Connection = room_to_remove.passages[passage_name].pop_back()
							var other_end_connection = _get_connection_from_array(
								conn_to_remove.room.passages[conn_to_remove.connected_passage],
								Connection.new(room_to_remove,passage_name)
							)
							conn_to_remove.room.passages[conn_to_remove.connected_passage].erase(other_end_connection)
							room_to_remove.passages[passage_name].erase(conn_to_remove)
							level.rooms.erase(room_name)
							if !rooms_names_to_remove.has(conn_to_remove.room):
								var modified_room:Room = conn_to_remove.room
								if !_validate_room_passages(modified_room, false):
									if modified_room.required:
										var message := "Map validation error: The required rooms "+room_name+ " and "+required_room_name+" are currently incompatible in terms of accessibility"
										printerr(message)
										still_valid = false
										keep_looping = false
										break
									if level.rooms.has(modified_room.name) and !rooms_names_to_remove.has(modified_room.name):
										rooms_names_to_remove.append(modified_room.name)
				for room_name:String in level.rooms:
					still_valid = still_valid and _validate_room_passages(level.rooms[room_name])
				if !still_valid:
					return null
	return map_data
static func _get_connection_from_array(arr: Array[Connection], connection_to_find: Connection) -> Connection:
	for conn in arr:
		if conn.equals(connection_to_find):
			return conn
	return null
	
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
	
static func _validate_room_passages(room:Room, print_error:bool=true):
	#Check if all the passages have at least one connection
	var still_valid:=true
	for room_passage_name:String in room.passages:
		if room.passages[room_passage_name].size() != 0:
			continue
		still_valid = false
		if print_error:
			var message := "Map validation error: the room "+room.name+ " has 0 connections from "+room_passage_name+" passage"
			printerr(message)
		else:
			break 
			#if it won't print the error message and it reached pass the first if 
			#then it can break and save some computation
	return still_valid
