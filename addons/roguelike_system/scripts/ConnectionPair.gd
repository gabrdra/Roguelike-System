class_name ConnectionPair extends Resource

var first:Connection
var second:Connection

func _init(_first:Connection, _second:Connection) -> void:
	first = _first
	second = _second

func _to_string() -> String:
	return first.to_string() + " - " + second.to_string()

func inverted_to_string() -> String:
	return second.to_string() + " - " + first.to_string()

#func equals(other_pair:ConnectionPair) -> bool:
	#return (
		#(first.equals(other_pair.first) or first.equals(other_pair.second)) and
		#(second.equals(other_pair.first) or second.equals(other_pair.second))
	#)
