class_name Demo2D extends RoomManager

@export_category("starting values")
@export var starter_room_name:String
@export var starter_level_name:String
@export var spawn_point_name:String
@onready var player_2d: CharacterBody2D = $Player2D
@onready var timer: Timer = $Timer
var entered_passage_name:String
var cooldown := false

func _ready() -> void:
	super()
	if starter_level_name == "":
		printerr("Starter level name is empty")
		return
	if starter_room_name == "":
		printerr("Starter room name is empty")
		return
	generate_level(starter_level_name)
	set_current_level(starter_level_name)
	set_current_room(starter_room_name)
	room_changed.connect(_on_room_changed)
	if spawn_point_name == null:
		printerr("spawn point name cannot be null")
	var spawn_point:Node2D = current_room_scene.get_node(spawn_point_name)
	player_2d.global_position = spawn_point.global_position
	_on_room_changed()
	
func _on_room_changed() -> void:
	var passages_node:Node2D = current_room_scene.get_node(passages_holder_name)
	if(!passages_node):
		printerr("There must be a node on the room, direct child of root, named "+passages_holder_name)
		return
	for child in passages_node.get_children():
		child.passage_entered.connect(_on_passage_entered)
		if child.name == entered_passage_name:
			player_2d.global_position = child.global_position
	

func _on_passage_entered(passage_name:String) -> void:
	if(cooldown):
		return
	cooldown = true
	print(passage_name)
	var conn:=get_connection_to_passage_from_current_room(passage_name)
	entered_passage_name = conn.connected_passage
	set_current_room(conn.room.name)
	timer.start()


func _on_timer_timeout() -> void:
	cooldown = false
