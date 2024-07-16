class_name SaveLoadData extends Node

static func save_plugin_data(path:String) -> void:
	var save := FileAccess.open(path,FileAccess.WRITE)
	if save == null:
		printerr("Failed to open file for writing")
		return
	var save_dict:={
		"current_level_name":RogueSys.current_level_name,
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
	#print(JSON.stringify(save_dict))
	save.store_string(JSON.stringify(save_dict))


static func load_plugin_data(path: String) -> void:
	pass
