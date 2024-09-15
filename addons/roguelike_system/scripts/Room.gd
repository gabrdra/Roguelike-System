class_name Room extends Resource

var name: String
var scene_uid: String
var required: bool
var max_passes: int
var passages: Dictionary 
#If static typing were avaliable passages would be Dictionary[String,Array[Connections]]
func _init(_name:String = "", _scene_uid:String = "", _required:bool = false,
 _max_passes:int = 1, _passages:Dictionary = {}):
	name = _name
	scene_uid = _scene_uid
	required = _required
	max_passes = _max_passes
	passages = _passages
