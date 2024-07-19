class_name Connection extends Resource

var room:Room
var connected_passage:String

func _init(_room = Room.new(), _connected_passage = ""):
	room = _room
	connected_passage = _connected_passage

func _to_string():
	return room.name +": "+ connected_passage
	
func equals(other_connection:Connection) -> bool:
	return (room.name == other_connection.room.name && 
		connected_passage == other_connection.connected_passage)
