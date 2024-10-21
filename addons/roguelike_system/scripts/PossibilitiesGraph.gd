@tool
extends HBoxContainer

@onready var rooms_container: VBoxContainer = $Container/ScrollContainer/List/RoomsContainer
@onready var graph_edit: GraphEdit = $GraphEdit
@onready var current_level_button: OptionButton = $Container/ScrollContainer/List/CurrentLevelButton

const node_colors := [Color.WHITE, Color.LIME_GREEN,Color.INDIAN_RED,Color.REBECCA_PURPLE,
	Color.LIGHT_YELLOW,Color.DARK_BLUE,Color.ORANGE,Color.ORCHID]
var levels_names: Array[String]
var current_focused_room := ""
var port_indexes: Dictionary = {}
var reverse_port_indexes: Dictionary = {}
func _set_current_level_button() -> void:
	levels_names.clear()
	current_level_button.clear()
	for level_name in RogueSys.map_data.levels:
		current_level_button.add_item(level_name)
		levels_names.append(level_name)
		if level_name==RogueSys.current_level_name:
			current_level_button.select(levels_names.size()-1)

func _populate_graph_edit(rooms:Dictionary) -> void:
	_clear_graph_edit()
	_spawn_rooms(rooms)
	_spawn_connections(rooms)
	graph_edit.arrange_nodes()

func _clear_graph_edit() -> void:
	graph_edit.clear_connections()
	for child in graph_edit.get_children():
		if child is GraphNode:
			graph_edit.remove_child(child)

func _spawn_connections(rooms:Dictionary) -> void:
	var already_used = {}
	for room_name in rooms:
		already_used[room_name]=true
		var room:Room = rooms[room_name]
		for passage_name in room.passages:
			for conn in room.passages[passage_name]:
				if already_used.has(conn.room.name):
					continue
				graph_edit.connect_node(room_name,port_indexes[room_name][passage_name], conn.room.name,port_indexes[conn.room.name][conn.connected_passage])

func _spawn_rooms(rooms:Dictionary) -> void:
	var local_port_indexes:= {}
	var local_reverse_port_indexes:= {}
	for room_name in rooms:
		var room:Room = rooms[room_name]
		var node:= GraphNode.new()
		node.title = room.name
		node.name = room.name
		local_port_indexes[room_name]={}
		local_reverse_port_indexes[room_name]=[]
		var i := 0
		for p in room.passages:
			local_port_indexes[room_name][p]=i
			local_reverse_port_indexes[room_name].append(p)
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
	port_indexes = local_port_indexes
	reverse_port_indexes = local_reverse_port_indexes

func _on_room_selected(button:Button) -> void:
	current_focused_room = button.text
	graph_edit.clear_connections()
	_spawn_connections_to_room(button.text, RogueSys.get_rooms())
	graph_edit.arrange_nodes()

func _spawn_connections_to_room(room_name:String, rooms:Dictionary) -> void:
	var room:Room = rooms[room_name]
	for passage_name:String in room.passages:
		for conn:Connection in room.passages[passage_name]:
			graph_edit.connect_node(room_name,port_indexes[room_name][passage_name], conn.room.name,port_indexes[conn.room.name][conn.connected_passage])

func fill_possibilities_graph() -> void:
	_set_current_level_button()
	_populate_graph_edit(RogueSys.get_rooms())
	#if not rooms_container:
		#print("rooms_container is null in fill_rooms_list")
		#return
	for r in rooms_container.get_children():
		r.queue_free()
	var rooms := RogueSys.get_rooms()
	for name in rooms:
		var button := Button.new()
		button.text = name
		button.button_down.connect(_on_room_selected.bind(button))
		rooms_container.add_child(button)

#func _on_visibility_changed() -> void:
	#if is_visible() == true:
		#fill_rooms_list()

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if current_focused_room != "" and !(current_focused_room == from_node or current_focused_room == to_node):
		return
	var from_room = RogueSys.get_room_by_name(from_node)
	var to_room = RogueSys.get_room_by_name(to_node)
	var from_conn := Connection.new(to_room, reverse_port_indexes[to_node][to_port])
	var passage_name:String = reverse_port_indexes[from_node][from_port]
	if RogueSys.check_if_connection_exists(from_room, from_conn, passage_name):
		RogueSys.remove_connection(from_room, from_conn, passage_name)
		graph_edit.disconnect_node(from_node,from_port,to_node,to_port)
	else:
		RogueSys.add_connection(from_room, from_conn, passage_name)
		graph_edit.connect_node(from_node,from_port,to_node,to_port)

func _on_clear_selection_button_down() -> void:
	current_focused_room = ""
	graph_edit.clear_connections()
	_spawn_connections(RogueSys.get_rooms())
	graph_edit.arrange_nodes()
