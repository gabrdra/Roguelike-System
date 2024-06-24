class_name Room

var name: String
var scene_uid: String
var required: bool
var max_passes: int
var passages: Dictionary 
#If static typing were avaliable passages would be Dictionary[String,Array[Connections]]

class Connection:
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
