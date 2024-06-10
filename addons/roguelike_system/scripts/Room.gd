class_name Room

var name: String
var scene_uid: String
var required: bool
var max_passes: int
var passages: Dictionary

class Connection:
	var room:Room
	var connected_passage:String
	
	func _to_string():
		return room.name +": "+ connected_passage
