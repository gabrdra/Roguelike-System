class_name LevelData extends Resource

var rooms:Dictionary = {}#Room name will be key and the room will be the value
var starter_room:Room

func _init(_rooms:={}, _starter_room:=Room.new()):
	rooms = _rooms
	starter_room = _starter_room

func duplicate_level_data() -> LevelData:
	var duplicated_rooms:= {}
	for origin_room_name:String in rooms:
		var origin_room:Room = rooms[origin_room_name]
		var duplicated_room := Room.new(
			origin_room.name,
			origin_room.scene_uid,
			origin_room.required,
			origin_room.max_passes
			)
		duplicated_rooms[duplicated_room.name] = duplicated_room
	#The following for is necessary to copy the connections 
	#with the references to the correct instances of each room
	for origin_room_name:String in rooms:
		var origin_room:Room = rooms[origin_room_name]
		for origin_room_passage_name in origin_room.passages:
			var origin_room_conns:Array = origin_room.passages[origin_room_passage_name]
			var duplicated_connections:Array[Connection] = []
			for origin_conn:Connection in origin_room_conns:
				duplicated_connections.append(
					Connection.new(
						duplicated_rooms[origin_conn.room.name], origin_conn.connected_passage
					)
				)
			duplicated_rooms[origin_room.name].passages[origin_room_passage_name]=duplicated_connections
	return LevelData.new(duplicated_rooms,duplicated_rooms[starter_room.name])
