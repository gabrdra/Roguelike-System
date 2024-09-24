@tool
extends HBoxContainer

@onready var rooms_container: VBoxContainer = $Container/ScrollContainer/List/RoomsContainer
@onready var graph_edit: GraphEdit = $GraphEdit

var node_colors := [Color.WHITE, Color.LIME_GREEN,Color.INDIAN_RED,Color.REBECCA_PURPLE,
	Color.LIGHT_YELLOW,Color.DARK_BLUE,Color.ORANGE,Color.ORCHID]

func _on_room_selected(button:Button) -> void:
	var room := RogueSys.get_room_by_name(button.text)
	var node:= GraphNode.new()
	node.title = room.name
	node.name = room.name
	#Change Variant.TYPE_NIL to Variant.DICTIONARY???
	var i := 0
	for p in room.passages:
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
	#button.disabled = true

func fill_rooms_list() -> void:
	if not rooms_container:
		print("rooms_container is null in fill_rooms_list")
		return
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
	graph_edit.connect_node(from_node,from_port,to_node,to_port)
