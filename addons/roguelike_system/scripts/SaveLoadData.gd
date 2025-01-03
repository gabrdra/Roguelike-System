class_name SaveLoadData extends Node

static func save_plugin_data(path:String) -> void:
	var save := FileAccess.open(path,FileAccess.WRITE)
	if save == null:
		printerr("Failed to open file for writing")
		return
	var save_dict:={
		"file_type":"save_data",
		"passages_holder_name":RogueSys.map_data.passages_holder_name,
		"current_level_name":RogueSys.current_level_name,
		"levels":[]
	}
	var levels_names := RogueSys.map_data.levels.keys()
	
	for level_name in levels_names:
		var level:LevelData = RogueSys.map_data.levels[level_name]
		var level_dict := {
			"name":level_name,
			"starter_room_name": null,
			"min_rooms":level.min_rooms,
			"max_rooms":level.max_rooms
		}
		if(level.starter_room!=null):
			level_dict["starter_room_name"] = level.starter_room.name
		level_dict["rooms"]=[]
		for room_name in level.rooms:
			var room:Room = level.rooms[room_name]
			var room_dict :={
				"name":room_name,
				"scene_uid":room.scene_uid,
				"required":room.required,
				"max_passes":room.max_passes,
				"passages":[]
			}
			for passage in room.passages:
				var connections = room.passages[passage]
				var passage_dict={
					"name":passage,
					"connections":[]
				}
				for connection in connections:
					passage_dict["connections"].append({
						"name":connection.room.name,
						"connected_passage":connection.connected_passage
					})
				room_dict["passages"].append(passage_dict)
			level_dict["rooms"].append(room_dict)
		save_dict["levels"].append(level_dict)
	save.store_string(JSON.stringify(save_dict))

static func load_plugin_data(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Failed to open file for reading")
		return false
	var file_content = file.get_as_text()
	file.close()
	var data_dict = JSON.parse_string(file_content)
	if data_dict == null:
		printerr("Error with plugin save file")
		return false
	if !data_dict.has("file_type"):
		printerr("Error with plugin save file")
		return false
	if data_dict["file_type"] != "save_data":
		printerr("Error with plugin save file")
		return false
	if !data_dict.has("passages_holder_name"):
		printerr("Error with plugin save file")
		return false
	var levels_array: Array = data_dict["levels"]
	var local_map_data := MapData.new()
	for level_dict in levels_array:
		var level := LevelData.new()
		for room_dict in level_dict["rooms"]:
			var room := Room.new()
			room.name = room_dict["name"]
			room.scene_uid = room_dict["scene_uid"]
			room.required = room_dict["required"]
			room.max_passes = room_dict["max_passes"]
			level.rooms[room.name]=room
		for  room_dict in level_dict["rooms"]:
			for passage_dict in room_dict["passages"]:
				var connections:Array[Connection]
				for connection_dict in passage_dict["connections"]:
					var connection := Connection.new(
						level.rooms[connection_dict["name"]],
						connection_dict["connected_passage"]
					)
					connections.append(connection)
				level.rooms[room_dict["name"]].passages[passage_dict["name"]] = connections
		if level_dict["starter_room_name"] != null:
			level.starter_room = level.rooms[level_dict["starter_room_name"]]
		level.min_rooms = level_dict["min_rooms"]
		level.max_rooms = level_dict["max_rooms"]
		local_map_data.levels[level_dict.name]=level
	local_map_data.passages_holder_name = data_dict["passages_holder_name"]
	RogueSys.map_data = local_map_data
	RogueSys.set_current_level(data_dict["current_level_name"])
	return true

static func export_data(map_data:MapData, path:String) -> void:
	var save := FileAccess.open(path,FileAccess.WRITE)
	if save == null:
		printerr("Failed to open file for writing the export data")
		return
	var save_dict:={
		"levels":[],
		"file_type":"exported_map_data",
		"passages_holder_name":map_data.passages_holder_name,
	}
	var levels_names:= map_data.levels.keys()
	
	for level_name in levels_names:
		var level:ValidatedLevelData = map_data.levels[level_name]
		var level_dict := {
			"name":level_name,
			"starter_room_name": level.starter_room.name,
			"possibilities": level.possibilities,
			"connection_pairs":level.connectionPairs,
			"min_rooms":level.min_rooms,
			"max_rooms":level.max_rooms
		}
		level_dict["rooms"]=[]
		for room_name in level.rooms:
			var room:Room = level.rooms[room_name]
			var room_dict :={
				"name":room_name,
				"scene_uid":room.scene_uid,
				"required":room.required,
				"max_passes":room.max_passes,
				"passages":[]
			}
			for passage in room.passages:
				var connections = room.passages[passage]
				var passage_dict={
					"name":passage,
					"connections":[]
				}
				for connection in connections:
					passage_dict["connections"].append({
						"name":connection.room.name,
						"connected_passage":connection.connected_passage
					})
				room_dict["passages"].append(passage_dict)
			level_dict["rooms"].append(room_dict)
		save_dict["levels"].append(level_dict)
	save.store_string(JSON.stringify(save_dict))

static func read_exported_data(path: String) -> MapData:
	var file = FileAccess.open(path, FileAccess.READ)
	var return_map_data = null
	if file == null:
		printerr("Failed to open file for reading")
		return return_map_data
	var file_content = file.get_as_text()
	file.close()
	var return_levels = {}
	var data_dict = JSON.parse_string(file_content)
	if data_dict == null:
		printerr("Error with exported map file")
		return return_map_data
	if !data_dict.has("file_type"):
		printerr("Error with exported map file")
		return return_map_data
	if data_dict["file_type"] != "exported_map_data":
		printerr("Error with exported map file")
		return return_map_data
	if !data_dict.has("passages_holder_name"):
		printerr("Error with exported map file")
		return return_map_data
	var levels_array: Array = data_dict["levels"]
	for level_dict in levels_array:
		var level := ValidatedLevelData.new()
		for room_dict in level_dict["rooms"]:
			var room := Room.new()
			room.name = room_dict["name"]
			room.scene_uid = room_dict["scene_uid"]
			room.required = room_dict["required"]
			room.max_passes = room_dict["max_passes"]
			level.rooms[room.name]=room
		for  room_dict in level_dict["rooms"]:
			for passage_dict in room_dict["passages"]:
				var connections:Array[Connection]
				for connection_dict in passage_dict["connections"]:
					var connection := Connection.new(
						level.rooms[connection_dict["name"]],
						connection_dict["connected_passage"]
					)
					connections.append(connection)
				level.rooms[room_dict["name"]].passages[passage_dict["name"]] = connections
		level.starter_room = level.rooms[level_dict["starter_room_name"]]
		level.min_rooms = level_dict["min_rooms"]
		level.max_rooms = level_dict["max_rooms"]
		#print(level_dict["possibilities"].size())
		level.possibilities = level_dict["possibilities"] as Array[Array]
		var conn_pairs:Array[ConnectionPair] = []
		for conn_pair_str in level_dict["connection_pairs"]:
			var conn_pair_str_split:PackedStringArray = conn_pair_str.split(" - ")
			var conn_pair_first_split:PackedStringArray  = conn_pair_str_split[0].split(": ")
			var conn_pair_second_split:PackedStringArray = conn_pair_str_split[1].split(": ")
			var conn_pair = ConnectionPair.new(
				Connection.new(
					level.rooms[conn_pair_first_split[0]],
					conn_pair_first_split[1]
				),
				Connection.new(
					level.rooms[conn_pair_second_split[0]],
					conn_pair_second_split[1]
				)
			)
			conn_pairs.append(conn_pair)
		level.connectionPairs = conn_pairs
		return_levels[level_dict.name]=level
	return_map_data = MapData.new(return_levels,data_dict["passages_holder_name"])
	return return_map_data

#This method is commented because it's use is only for debugging
#static func save_level_data_json(level_data:LevelData, level_name:String, path:String) ->void:
	#var save := FileAccess.open(path,FileAccess.WRITE)
	#if save == null:
		#printerr("Failed to open file")
		#return
	#var level:LevelData = level_data
	#var level_dict := {
		#"name":level_name,
		#"starter_room_name": null
	#}
	#if(level.starter_room!=null):
		#level_dict["starter_room_name"] = level.starter_room.name
	#level_dict["rooms"]=[]
	#for room_name in level.rooms:
		#var room:Room = level.rooms[room_name]
		#var room_dict :={
			#"name":room_name,
			#"scene_uid":room.scene_uid,
			#"required":room.required,
			#"max_passes":room.max_passes,
			#"passages":[]
		#}
		#for passage in room.passages:
			#var connections = room.passages[passage]
			#var passage_dict={
				#"name":passage,
				#"connections":[]
			#}
			#passage_dict["connections"].append({
				#"name":connections.room.name,
				#"connected_passage":connections.connected_passage
			#})
			#room_dict["passages"].append(passage_dict)
		#level_dict["rooms"].append(room_dict)
	#save.store_string(JSON.stringify(level_dict))
