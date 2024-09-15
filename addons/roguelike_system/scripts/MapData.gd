class_name MapData extends Node

var levels: Dictionary
var passages_holder_name:String

func _init(_levels:={}, _passages_holder_name:="Passages"):
	levels=_levels
	passages_holder_name= _passages_holder_name
