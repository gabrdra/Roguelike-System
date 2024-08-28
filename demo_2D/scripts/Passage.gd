extends Node2D
signal passage_entered(passage_name:String)
func _ready() -> void:
	for child in get_children():
		if child is Area2D:
			child.body_entered.connect(check_player_entered)
	
func check_player_entered(body:Node2D) -> void:
	if body.is_in_group("player"):
		passage_entered.emit(name)
