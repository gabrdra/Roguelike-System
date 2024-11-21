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

func _choose_random_element_array(array:Array, weights:Array) -> int:
	return array[random.rand_weighted(weights)]

func generate_level(input_level:ValidatedLevelData, input_seed:int = 0) -> LevelData:
	random = RandomNumberGenerator.new()
	if input_seed!=0:
		random.seed = input_seed
	var used_rooms := {}
	var nodes := input_level.nodes
	var conn_pairs := input_level.connectionPairs
	var curr_node := input_level.root_node
	while true:
		if curr_node == input_level.root_node:
			curr_node = nodes[_choose_random_element_array(curr_node.children, curr_node.children_frequency)]
			continue
		elif curr_node.connection_pair_id == -2:
			break #-2 is the connection_pair_id for the end node
		var conn_pair:ConnectionPair = conn_pairs[curr_node.connection_pair_id]
		if !used_rooms.has(conn_pair.first.room.name):
			used_rooms[conn_pair.first.room.name] = conn_pair.first.room
		if !used_rooms.has(conn_pair.second.room.name):
			used_rooms[conn_pair.second.room.name] = conn_pair.second.room
		conn_pair.first.room.passages[conn_pair.first.connected_passage] = conn_pair.second
		conn_pair.second.room.passages[conn_pair.second.connected_passage] = conn_pair.first
		curr_node = nodes[_choose_random_element_array(curr_node.children, curr_node.children_frequency)]
	var return_level := LevelData.new()
	return_level.rooms = used_rooms
	return_level.starter_room = used_rooms[input_level.starter_room.name]
	return return_level
