class_name RogueSysGenerator extends Node

var random: RandomNumberGenerator
#For now, max_passes will be ignored and every room will be considered as having it set to 1
func _collapse(collapsed_room:Room, rooms:Dictionary) -> void:
	for passage_name in collapsed_room.passages:
		var passage = collapsed_room.passages[passage_name]
		if typeof(passage) == TYPE_ARRAY:
			for conn in passage:
				conn.room.passages[conn.connected_passage] = collapsed_room
		else:
			passage.room.passages[passage.connected_passage] = collapsed_room
func _propagate(rooms:Dictionary, used_rooms:Dictionary) -> bool:
	var stop_loop = false
	while !stop_loop:
		stop_loop=true
		var rooms_to_remove:Dictionary #Using a Dictionary because gdscript doesn't have a set type
		for room_name in rooms:
			var room: Room = rooms[room_name]
			for passage_name in room.passages:
				var passage = room.passages[passage_name]#this can be an array of connections or just a connection
				if typeof(passage)==TYPE_ARRAY:
					var remaining_passages:Array = passage.filter(
						func(c:Connection):
							#checks if there is a connection to the current roomon the other room,
							#if it exists, this connection will be kept, 
							#if it doesn't, then it shouldn't be kept
							var other_room_corresponding_passage = c.room[c.connected_passage]
							if typeof(other_room_corresponding_passage) == TYPE_ARRAY:
								for other_c in other_room_corresponding_passage:
									if(other_c.room.name == room.name):
										stop_loop = false
										return true
							else:
								if c.room.passages[c.connected_passage].room.name == room.name:
									stop_loop = false
									return true
							return false
					)
					#if no connections remain, then this room need to be removed
					if remaining_passages.size() == 0:
						rooms_to_remove[room.name] = true
					room.passages[passage_name]=remaining_passages
				else:
					if passage == null:
						room.passages[passage_name]=null
						rooms_to_remove[room.name]=true
					if(passage.room.passages[passage.connected_passage].room != room): 
						#the line above should work but if there is a bug it might be 
						#because these are the same info but not pointing to the same memory address
						room.passages[passage_name]=null
						rooms_to_remove[room.name]=true
		while rooms_to_remove.size()>0:
			var room_to_remove:Room = rooms_to_remove[rooms_to_remove.keys()[0]]
			if used_rooms.has(room_to_remove.name):
				return false 
				#a room that should be removed cannot be a room in use,
				#this would lead to an inconsistent level
			if !rooms.has(room_to_remove):
				continue
			for passage_name in room_to_remove.passages:
				var passage = room_to_remove.passages[passage_name]
				if typeof(passage) == TYPE_ARRAY:
					for conn:Connection in passage:
						#remove the connections to the room that is going to be erased
						#no need to remove the connections on the room it self,
						#since it's already going to be erased
						var other_passage = conn.room.passages[conn.connected_passage]
						if typeof(other_passage) == TYPE_ARRAY:
							var remaining_other_passages:Array = other_passage.filter(
								func(other_c:Connection):
									if other_c.room.name == room_to_remove.name:
										return false #is the room that should be removed
									return true #is not
							)
							if remaining_other_passages.size() == 0:
								rooms_to_remove[conn.room.name]=true
								#should remove the room that had it's passaged updates
							conn.room.passages[conn.connected_passage] = remaining_other_passages
						else:
							if other_passage == null:
								rooms_to_remove[conn.room.name]=true
							if(conn.room == room_to_remove): 
								#the line above should work but if there is a bug it might be 
								#because these are the same info but not pointing to the same memory address
								rooms_to_remove[conn.room.name]=true
			rooms.erase(room_to_remove.name)
	return true

func _lowest_entropy(rooms:Dictionary) -> Array[Room]:
	var lowest_entropy_value := 9223372036854775807 #maximum int
	var lowest_entropy_dict := {}
	for room_name in rooms:
		var room:Room = rooms[room_name]
		for passage_name in room.passages:
			var passage = room.passages[passage_name]
			#if it's not an array it means it's point to a collapsed room
			#and in that case it shouldn't count it's entropy taking it into account
			if typeof(passage)==TYPE_ARRAY:
				var local_entropy = passage.size()
				if local_entropy==0:
					printerr("the passage shouldn't be able to be 0 here")
					return []
				if local_entropy < lowest_entropy_value:
					lowest_entropy_value = local_entropy
					lowest_entropy_dict.clear()
					for conn:Connection in passage:
							lowest_entropy_dict[conn.room.name]=true
			elif passage==null:
				printerr("the passage shouldn't be able to be null here")
				return []
	if lowest_entropy_dict == {}:
		return []
	var lowest_entropy_array := []
	for lowest_entropy_name in lowest_entropy_dict:
		lowest_entropy_array.append(lowest_entropy_dict[lowest_entropy_name])
	return lowest_entropy_array
	
func generate_level(input_level:LevelData, input_seed:int, attempts:int) -> LevelData:
	random = RandomNumberGenerator.new()
	random.seed = input_seed
	for i in range(attempts):
		var level:=input_level.duplicate(true)
		var rooms:Dictionary = level.rooms
		var used_rooms:Dictionary
		for room_name in rooms:
			print(room_name) #just to check if by deleting a room it's not skipping others
			if rooms[room_name].required:
				_collapse(rooms[room_name], rooms)
				used_rooms[room_name]=rooms[room_name]
				var valid:=_propagate(rooms,used_rooms)
				if not valid:
					printerr("Impossible to create a valid level with the given level as input")
					return LevelData.new()
		while(true):
			var lowest_entropy_array = _lowest_entropy(rooms)
			if lowest_entropy_array.is_empty():
				var successful_level_data = LevelData.new()
				successful_level_data.starter_room = input_level.starter_room
				successful_level_data.rooms = rooms
				return successful_level_data
			var collapsed_room:Room = lowest_entropy_array[random.randi_range(0,lowest_entropy_array.size()-1)]
			_collapse(collapsed_room,rooms)
			used_rooms[collapsed_room.name]=collapsed_room
			var valid:=_propagate(rooms,used_rooms)
			if not valid:
				break
		
	return LevelData.new()
