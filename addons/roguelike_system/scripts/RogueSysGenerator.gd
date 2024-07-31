class_name RogueSysGenerator extends Node

var random: RandomNumberGenerator

func print_passages(passages:Dictionary) -> void:
	for passage_name in passages:
		print(passage_name+":")
		print(passages[passage_name])

func print_dict_keys(dict:Dictionary) -> void:
	print("print_dict_keys")
	for d in dict.keys():
		print(d)
	print("end print_dict_keys")

#For now, max_passes will be ignored and every room will be considered as having it set to 1

func _get_all_uncollapsed_passages(rooms:Dictionary) -> Array[OutgoingPassage]:
	var outgoing_passages:Array[OutgoingPassage] = []
	for room_name in rooms:
		var room:Room = rooms[room_name]
		for passage_name in room.passages:
			var passage = room.passages[passage_name]
			if typeof(passage) == TYPE_ARRAY:
				outgoing_passages.append(OutgoingPassage.new(room,passage_name))
	return outgoing_passages

func _choose_random_element_array(array:Array):
	return array[random.randi_range(0,array.size()-1)]


func generate_level(input_level:LevelData, input_seed:int, attempts:int) -> LevelData:
	random = RandomNumberGenerator.new()
	if input_seed != 0:
		random.seed = input_seed
	if attempts == 0:
		attempts = 9223372036854775807
	for i in range(attempts):
		var level:=input_level #needs to duplicate the input_level in order to not mess with it during attempts
		var rooms:Dictionary = level.rooms
		var used_rooms:Dictionary
		#adds all required rooms to used_rooms dictionary
		for room_name in rooms:
			var room:Room = rooms[room_name]
			if room.required:
				used_rooms[room_name]=room
		
		var passages_to_collapse:Array[OutgoingPassage] = _get_all_uncollapsed_passages(used_rooms)
		var passages_with_single_element:Array[OutgoingPassage] = []
		for out_passage in passages_to_collapse:
			if out_passage.room.passages[out_passage.passage_name].size() == 1:
				passages_with_single_element.append(out_passage)
		while !passages_with_single_element.is_empty():
			var chosen_passage:OutgoingPassage = passages_with_single_element.pop_back()
			var other_side_passage:Connection = chosen_passage.room.passages[chosen_passage.passage_name][0]
			chosen_passage.room.passages[chosen_passage.passage_name] = other_side_passage
			other_side_passage.room.passages[other_side_passage.connected_passage]=chosen_passage.as_connection()
			used_rooms[other_side_passage.room.name] = other_side_passage.room
			for passage_name in other_side_passage.room.passages:
				var passage = other_side_passage.room.passages[passage_name]
				if typeof(passage) == TYPE_ARRAY:
					if passage.size()==1:
						passages_with_single_element.append(OutgoingPassage.new(passage[0].room, passage[0].connected_passage))
		var successful := true
		while successful:
			#gets all uncollapsed passages that belong to the required rooms
			passages_to_collapse = _get_all_uncollapsed_passages(used_rooms)
			if passages_to_collapse.is_empty():
				break
			var chosen_passage_to_collapse:OutgoingPassage = passages_to_collapse[random.randi_range(0,passages_to_collapse.size()-1)]
			#Performs a random walk until reaches a dead end or another room that already is on the used_rooms dictionary
			while(true):
				var destination:Connection =_choose_random_element_array(chosen_passage_to_collapse.room.passages[chosen_passage_to_collapse.passage_name])
				#sets the passages between the rooms to have only the collapsed connection
				chosen_passage_to_collapse.room.passages[chosen_passage_to_collapse.passage_name] = destination
				destination.room.passages[destination.connected_passage] = chosen_passage_to_collapse.as_connection()
				if(used_rooms.has(destination.room.name)):
					break #found a room that was already in use
				used_rooms[destination.room.name] = destination.room #adds room as being used
				#I'm not really sure about this whole passages_with_single_element part...
				var possible_next_outgoing_passage:Array[OutgoingPassage]=[]
				for passage_name in destination.room.passages:
					var passage = destination.room.passages[passage_name]
					if typeof(passage) == TYPE_ARRAY:
						if passage.size()==1:
							passages_with_single_element.append(OutgoingPassage.new(passage[0].room, passage[0].connected_passage))
						else:
							for p:Connection in passage:
								possible_next_outgoing_passage.append(OutgoingPassage.new(p.room,p.connected_passage))
				while !passages_with_single_element.is_empty():
					var chosen_passage:OutgoingPassage = passages_with_single_element.pop_back()
					var other_side_passage:Connection = chosen_passage.room.passages[chosen_passage.passage_name][0]
					chosen_passage.room.passages[chosen_passage.passage_name] = other_side_passage
					other_side_passage.room.passages[other_side_passage.connected_passage]=chosen_passage.as_connection()
					used_rooms[other_side_passage.room.name] = other_side_passage.room
					for passage_name in other_side_passage.room.passages:
						var passage = other_side_passage.room.passages[passage_name]
						if typeof(passage) == TYPE_ARRAY:
							if passage.size()==1:
								passages_with_single_element.append(OutgoingPassage.new(passage[0].room, passage[0].connected_passage))
				if possible_next_outgoing_passage.size()==0:
					break
				chosen_passage_to_collapse = _choose_random_element_array(possible_next_outgoing_passage)
		var return_level:LevelData = LevelData.new()
		return_level.rooms = used_rooms
		return_level.starter_room = input_level.starter_room
		return return_level
	return LevelData.new()


class OutgoingPassage:
	#This is basically the same as a connection but the room is the room where the passage is leading out of
	# and the passage is the outgoing passage
	var room:Room
	var passage_name:String
	func _init(_room = Room.new(), _passage_name = ""):
		room = _room
		passage_name = _passage_name
	func as_connection() -> Connection:
		return Connection.new(room,passage_name)
