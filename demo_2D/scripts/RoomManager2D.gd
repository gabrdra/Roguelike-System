class_name RoomManager2D extends Node

@export var map_data_path:String

var raw_map_data:={}
var generated_levels := {}
var current_level:LevelData
var current_room_name:String
var current_room_scene:Node
var rogue_sys_generator:RogueSysGenerator = RogueSysGenerator.new()
var passages_holder_name:String
#Emitted when either generate_level or regenerate_level finishes
signal level_generated
signal room_changed

func _ready() -> void:
	if map_data_path=="":
		printerr("map data location needs to be assigned in the inspector")
		return
	raw_map_data = SaveLoadData.read_exported_data(map_data_path)
	passages_holder_name = raw_map_data["passages_holder_name"]

#Generates a level if it doesn't exist already
func generate_level(level_name:String, random_seed:int = 0) -> void:
	if generated_levels.has(level_name):
		printerr("This level already exists")
		return
	if raw_map_data.is_empty():
		printerr("map data is empty")
		return
	if not raw_map_data.has(level_name):
		printerr("There is no corresponding level in the map data")
		return
	generated_levels[level_name] = rogue_sys_generator.generate_level(raw_map_data[level_name], random_seed) #the attempts will be removed later
	level_generated.emit()
	
#Generates a level even if it already exists
func regenerate_level(level_name:String, random_seed:int = 0) -> void:
	if raw_map_data.is_empty():
		printerr("map data is empty")
		return
	if not raw_map_data.has(level_name):
		printerr("There is no corresponding level in the map data")
		return
	generated_levels[level_name] = rogue_sys_generator.generate_level(raw_map_data[level_name], random_seed)
	level_generated.emit()

func set_current_level(level_name:String) -> void:
	if not generated_levels.has(level_name):
		printerr("The level "+ level_name + " doesn't exist")
		return
	current_level = generated_levels[level_name]

func set_current_room(room_name:String) -> void:
	if current_level == null:
		printerr("The current level is null")
		return
	if not current_level.rooms.has(room_name):
		printerr("There is no "+room_name+ " in the current instance of the level")
		return
	if current_room_scene != null:
		current_room_scene.queue_free()
		await current_room_scene.tree_exited
		current_room_scene = null
		current_room_name = ""
	current_room_name = room_name
	var loaded_room := load(current_level.rooms[current_room_name].scene_uid)
	current_room_scene = loaded_room.instantiate()
	add_child(current_room_scene)
	room_changed.emit()

func get_connection_to_passage_from_current_room(passage_name:String) -> Connection:
	return get_connection_to_passage(passage_name, current_room_name)

func get_connection_to_passage(passage_name:String, room_name:String) -> Connection:
	return current_level.rooms[room_name].passages[passage_name]
