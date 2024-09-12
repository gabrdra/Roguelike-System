class_name SaveLoadData extends Node

static func save_plugin_data(path:String) -> void:
	var save := FileAccess.open(path,FileAccess.WRITE)
	if save == null:
		printerr("Failed to open file for writing")
		return
	var save_dict:={
		"file_type":"save_data",
		"current_level_name":RogueSys.current_level_name,
		"levels":[]
	}
	var levels_names := RogueSys.levels.keys()
	
	for level_name in levels_names:
		var level:LevelData = RogueSys.levels[level_name]
		var level_dict := {
			"name":level_name,
			"starter_room_name": null
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

static func load_plugin_data(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		RogueSys.throw_error.emit("Failed to open file for reading")
		printerr("Failed to open file for reading")
		return
	var file_content = file.get_as_text()
	file.close()
	var data_dict = JSON.parse_string(file_content)
	if data_dict == null:
		RogueSys.throw_error.emit("Error with plugin save file")
		printerr("Error with plugin save file")
		return
	if !data_dict.has("file_type"):
		RogueSys.throw_error.emit("Error with plugin save file")
		printerr("Error with plugin save file")
		return
	if data_dict["file_type"] != "save_data":
		RogueSys.throw_error.emit("Error with plugin save file")
		printerr("Error with plugin save file")
		return
	var levels_array: Array = data_dict["levels"]
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
		RogueSys.levels[level_dict.name]=level
	RogueSys.set_current_level(data_dict["current_level_name"])

static func export_data(path:String) -> void:
	var save := FileAccess.open(path,FileAccess.WRITE)
	if save == null:
		printerr("Failed to open file for writing the export data")
		return
	var save_dict:={
		"levels":[]
	}
	var levels_names:= RogueSys.levels.keys()
	
	for level_name in levels_names:
		var level:LevelData = RogueSys.levels[level_name]
		var level_dict := {
			"name":level_name,
			"starter_room_name": null
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

static func read_exported_data(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Failed to open file for reading")
		return {}
	var file_content = file.get_as_text()
	file.close()
	var return_levels = {}
	var data_dict = JSON.parse_string(file_content)
	var levels_array: Array = data_dict["levels"]
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
		level.starter_room = level.rooms[level_dict["starter_room_name"]]
		return_levels[level_dict.name]=level
	return return_levels


static func save_level_data_json(level_data:LevelData, level_name:String, path:String) ->void:
	var save := FileAccess.open(path,FileAccess.WRITE)
	if save == null:
		printerr("Failed to open file")
		return
	var level:LevelData = level_data
	var level_dict := {
		"name":level_name,
		"starter_room_name": null
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
			passage_dict["connections"].append({
				"name":connections.room.name,
				"connected_passage":connections.connected_passage
			})
			room_dict["passages"].append(passage_dict)
		level_dict["rooms"].append(room_dict)
	save.store_string(JSON.stringify(level_dict))
