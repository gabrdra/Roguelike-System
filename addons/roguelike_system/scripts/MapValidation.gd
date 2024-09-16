class_name MapValidation extends Node

static func validate_map(map_data:MapData) -> MapData:
	var keep_checking:=true
	for level_name:String in map_data.levels:
		var level:LevelData = map_data.levels[level_name]
		for room_name:String in level.rooms:
			var room:Room = level.rooms[room_name]
			keep_checking = keep_checking and _validate_room(room, map_data.passages_holder_name)
		#Check if there is an invalid connection
		#starting from each required room, check what other rooms are reachable
		#if a room is not reachable, remove it from the level
		#if a removed room was a required room it means that the level is impossible to be generated
		#repeat for each required room until no changes are made
	return null
	
static func _validate_room(room:Room, passages_holder_name:String) -> bool:
	var keep_checking:=true
	#Check if the passages exist on the Room in the same way as in the scene
	var room_scene := ResourceLoader.load(room.scene_uid)
	var passages_node = room_scene.get_node(passages_holder_name)
	if(!passages_node):
		var message := "Map validation error: room " + room.name +"lacks the node "+passages_holder_name
		printerr(message)
		keep_checking = false
		return keep_checking
	var passages_scene:Array[Node] = passages_node.get_children()
	var passages_found:=0
	for passage_scene:Node in passages_scene:
		if room.passages.has(passage_scene.name):
			passages_found+=1
		else:
			var message := "Map validation error: scene corresponding to room " + room.name +" has "+passage_scene.name+" while the room inside the plugin doesn't"
			printerr(message)
			keep_checking = false
	if passages_found!=room.passages.size():
		#at least one passage that should exists in the scene, doesn't exist
		var message := "Map validation error: the room "+room.name+ " has "+str(room.passages.size()-passages_found)+" passage(s) more than it's corresponding scene"
		printerr(message)
		keep_checking = false
	#Check if all the passages have at least one connection
	for room_passage_name:String in room.passages:
		if room.passages[room_passage_name].size() == 0:
			var message := "Map validation error: the room "+room.name+ " has 0 connections from "+room_passage_name+" passage"
			printerr(message)
			keep_checking = false
	return keep_checking
