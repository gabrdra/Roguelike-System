@tool
extends VBoxContainer

@onready var export_data_selection: FileDialog = $ExportDataSelection
@onready var seed_input: SpinBox = $HBoxContainer/SeedInput
@onready var graph_edit: GraphEdit = $GraphEdit
@onready var chosen_level_button: OptionButton = $HBoxContainer/ChosenLevelButton

var file_path := ""
var possible_levels := []
var levels_dict := {}
var seed := 0
var possible_level_chosen := 0
var node_colors := [Color.WHITE, Color.LIME_GREEN,Color.INDIAN_RED,Color.REBECCA_PURPLE,
	Color.LIGHT_YELLOW,Color.DARK_BLUE,Color.ORANGE,Color.ORCHID]

func _on_export_data_selection_button_button_down() -> void:
	export_data_selection.popup_centered_ratio(0.5)

func _on_generate_button_button_down() -> void:
	if file_path.is_empty():
		printerr("no file was chosen")
		return
	var generator:RogueSysGenerator = RogueSysGenerator.new()
	
	var generated_level:LevelData = generator.generate_level(levels_dict[possible_levels[possible_level_chosen]],seed,100)
	#SaveLoadData.save_level_data_json(generated_level, "Level 1", "res://demo/export_data/Level1testjson.json")
	_create_visualization(generated_level)
func _on_export_data_selection_file_selected(path: String) -> void:
	file_path = path
	levels_dict = SaveLoadData.read_exported_data(file_path)
	levels_dict = levels_dict["levels"]
	possible_levels = levels_dict.keys()
	_fill_chosen_level_button()

func _fill_chosen_level_button() -> void:
	possible_level_chosen = 0
	chosen_level_button.clear()
	for level_name in possible_levels:
		chosen_level_button.add_item(level_name)
	chosen_level_button.select(possible_level_chosen)

func _create_visualization(level:LevelData):
	_clear_visualization()
	var portIndexes = _spawn_rooms(level.rooms)
	_spawn_connections(level.rooms, portIndexes)
	graph_edit.arrange_nodes()
func _spawn_connections(rooms:Dictionary, portIndexes:Dictionary) -> void:
	var already_used = {}
	for room_name in rooms:
		already_used[room_name]=true
		var room:Room = rooms[room_name]
		for passage_name in room.passages:
			var conn:Connection = room.passages[passage_name]
			if already_used.has(conn.room.name):
				continue
			graph_edit.connect_node(room_name,portIndexes[room_name][passage_name], conn.room.name,portIndexes[conn.room.name][conn.connected_passage])

func _spawn_rooms(rooms:Dictionary) -> Dictionary:
	var portIndexes:= {}
	for room_name in rooms:
		var room:Room = rooms[room_name]
		var node:= GraphNode.new()
		node.title = room.name
		node.name = room.name
		portIndexes[room_name]={}
		var i := 0
		for p in room.passages:
			portIndexes[room_name][p]=i
			var node_color:Color = node_colors[(i+1)%node_colors.size()]
			node.set_slot(i,true,Variant.Type.TYPE_NIL,node_color,true,Variant.Type.TYPE_NIL,node_color)
			var slot_node := Label.new()
			slot_node.text = p
			slot_node.custom_minimum_size = Vector2(0,40)
			slot_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			node.add_child(slot_node)
			i+=1
		#Set offset according to graphedit size
		node.position_offset = Vector2(100,100)
		node.resizable = true
		node.size = Vector2(100,100)
		graph_edit.add_child(node)
	return portIndexes

func _clear_visualization() -> void:
	graph_edit.clear_connections()
	for child in graph_edit.get_children():
		if child is GraphNode:
			graph_edit.remove_child(child)

func _on_seed_input_value_changed(value: float) -> void:
	seed = value

func _on_chosen_level_button_item_selected(index: int) -> void:
	possible_level_chosen = index
