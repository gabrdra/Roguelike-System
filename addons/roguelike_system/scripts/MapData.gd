class_name MapData extends Resource

var levels: Dictionary
var passages_holder_name:String

func _init(_levels:={}, _passages_holder_name:="Passages"):
	levels = _levels
	passages_holder_name = _passages_holder_name

func duplicate_map_data() -> MapData:
	#This method necessary because .duplicate() doesn't work with Dictionaries and Arrays
	var duplicated_levels := {}
	for origin_level_name in levels:
		var duplicated_level:LevelData = levels[origin_level_name].duplicate_level_data()
	return MapData.new(duplicated_levels, passages_holder_name)
