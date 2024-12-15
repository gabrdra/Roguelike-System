extends Node3D
signal passage_entered(passage_name:String)
var entered := false
func _ready() -> void:
	for child in get_children():
		if child is Area3D:
			child.body_entered.connect(check_player_entered)
	
func check_player_entered(body:Node3D) -> void:
	if body.is_in_group("player"):
		print("Press left mouse button or 'E' to enter the passage.")
		entered = true
		return
	entered = false
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact_passage") and entered:
		passage_entered.emit(name)
