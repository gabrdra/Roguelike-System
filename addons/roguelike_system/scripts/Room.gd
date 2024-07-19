class_name Room extends Resource

var name: String
var scene_uid: String
var required: bool
var max_passes: int
var passages: Dictionary 
#If static typing were avaliable passages would be Dictionary[String,Array[Connections]]
