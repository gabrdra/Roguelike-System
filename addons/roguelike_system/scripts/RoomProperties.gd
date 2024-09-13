@tool
extends PanelContainer

signal rooms_changed

@onready var file_selection:FileDialog = $ScrollContainer/VBoxContainer/Scene/SceneButton/FileSelection
@onready var scene_path_label: Label = $ScrollContainer/VBoxContainer/Scene/ScenePathLabel
@onready var room_name_input: TextEdit = $ScrollContainer/VBoxContainer/Name/RoomNameInput
@onready var max_passes_input: SpinBox = $ScrollContainer/VBoxContainer/MaxPasses/MaxPassesInput
@onready var required_button: CheckButton = $ScrollContainer/VBoxContainer/Required/RequiredButton
@onready var passages_holder: VBoxContainer = $ScrollContainer/VBoxContainer/ListPassages/PassagesHolder
@onready var adjacency_selection: Window = $ScrollContainer/VBoxContainer/MaxPasses/AdjacencySelection
@onready var current_passage_label: Label = $ScrollContainer/VBoxContainer/MaxPasses/AdjacencySelection/Background/SelectionContainer/CurrentPassageHolder/CurrentPassageLabel
@onready var other_rooms_holder: VBoxContainer = $ScrollContainer/VBoxContainer/MaxPasses/AdjacencySelection/Background/SelectionContainer/MainContent/OtherRoomsHolder
@onready var selected_other_room_passages_holder: VBoxContainer = $ScrollContainer/VBoxContainer/MaxPasses/AdjacencySelection/Background/SelectionContainer/MainContent/SelectedOtherRoomPassagesHolder
@onready var delete_room_confirmation: ConfirmationDialog = $DeleteRoomConfirmation

enum State {CREATE, UPDATE}
var current_state:State
var current_room:Room;
var current_passage:String;
var room_old_name:String;
var connections_to_add:Dictionary #Array[Connection]
var connections_to_remove:Dictionary #Array[Connection]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_new_empty_room()

func create_new_empty_room() -> void:
	current_state = State.CREATE
	connections_to_add.clear()
	connections_to_remove.clear()
	current_room = Room.new()
	current_room.max_passes = 1
	current_room.required = false
	room_old_name = ""
	fill_interface()

func open_delete_current_room_dialog() -> void:
	if(current_state == State.CREATE):
		create_new_empty_room()
		return
	delete_room_confirmation.dialog_text = "Delete "+ current_room.name+"?"
	delete_room_confirmation.popup_centered()

func retrieve_existing_room(room_name:String) -> void:
	current_state = State.UPDATE
	connections_to_add.clear()
	connections_to_remove.clear()
	var room := RogueSys.get_room_by_name(room_name)
	room_old_name = room.name
	current_room = room
	fill_interface()

func fill_interface() -> void:
	if(current_room.scene_uid.is_empty()):
		scene_path_label.text = ""
	else:
		scene_path_label.text = ResourceUID.get_id_path(
			ResourceUID.text_to_id(current_room.scene_uid)
			)
	room_name_input.text = current_room.name
	max_passes_input.value = current_room.max_passes
	required_button.set_pressed_no_signal(current_room.required)
	update_passages()

func set_passages_from_scene() -> void:
	if(current_room.scene_uid.is_empty()):
		printerr("Scene hasn't been selected yet")
		return
	var scene_loaded := ResourceLoader.load(current_room.scene_uid)
	if !scene_loaded:
		var message := "Error loading resource"
		RogueSys.throw_error.emit(message)
		printerr(message)
		return
	var scene_instance = scene_loaded.instantiate()
	if(!scene_instance):
		var message := "Error instancing scene"
		RogueSys.throw_error.emit(message)
		printerr(message)
		return
	var passages_node = scene_instance.get_node(RogueSys.passages_holder_name)
	if(!passages_node):
		var message := "There must be a node on the scene, direct child of root, named "+ RogueSys.passages_holder_name
		RogueSys.throw_error.emit(message)
		printerr(message)
		return
	var passage_children = passages_node.get_children()
	current_room.passages = {}
	for p in passage_children:
		#print(p.name)
		if(current_room.passages.has(p.name)):
			printerr("There is more than one passage with the same name")
			current_room.passages = {}
			return
		current_room.passages[p.name]=[]
	update_passages()

func update_passages()->void:
	for child in passages_holder.get_children():
		child.queue_free()
	for p in current_room.passages:
		var passage_container:= VBoxContainer.new()
		var name_and_button_container := HBoxContainer.new()
		passage_container.add_child(name_and_button_container)
		var passage_name := Label.new()
		passage_name.text ="- "+ p
		name_and_button_container.add_child(passage_name)
		var change_adjacencies_button := Button.new()
		change_adjacencies_button.text = "Change adjacencies"
		change_adjacencies_button.button_down.connect(
			_on_change_adjacencies_button_down.bind(p)
			)
		name_and_button_container.add_child(change_adjacencies_button)
		var possibilities_text := RichTextLabel.new()
		possibilities_text.bbcode_enabled=true
		possibilities_text.append_text("[font_size=16]Already in: [/font_size] \n")
		for possibility in current_room.passages[p]:
			possibilities_text.append_text("|- " + possibility._to_string()+" ")
		if(!connections_to_add.has(p)):
			connections_to_add[p]=[]
		if(connections_to_add[p]!=[]):
			possibilities_text.append_text("\n\n[font_size=16]To add: [/font_size] \n")
			for conn in connections_to_add[p]:
				possibilities_text.append_text("|-" + conn._to_string()+"")
		if(!connections_to_remove.has(p)):
			connections_to_remove[p]=[]
		if(connections_to_remove[p]!=[]):
			possibilities_text.append_text("\n\n[font_size=16]To remove: [/font_size] \n")
			for conn in connections_to_remove[p]:
				possibilities_text.append_text("|-" + conn._to_string()+"")
		possibilities_text.fit_content = true
		passage_container.add_child(possibilities_text)
		var separator:= HSeparator.new()
		passage_container.add_child(separator)
		passages_holder.add_child(passage_container)

func check_connection_array_has_element(arr:Array, element:Connection) -> bool:
	for i in arr:
		if element.equals(i): 
			return true
	return false

func delete_connection_from_array(arr:Array, element:Connection) -> bool:
	for i in arr:
		if(element.equals(i)):
			arr.erase(i)
			return true
	return false

func _on_change_adjacencies_button_down(curr_passage:String) -> void:
	current_passage = curr_passage
	for child in other_rooms_holder.get_children():
		child.queue_free()
	for child in selected_other_room_passages_holder.get_children():
		child.queue_free()
	current_passage_label.text = current_room.name+ ": " +current_passage
	adjacency_selection.popup_centered_ratio(0.5)
	for other_room_name in RogueSys.get_rooms():
		var other_room: Room = RogueSys.get_room_by_name(other_room_name)
		if(other_room.name == current_room.name):
			continue
		var other_room_button := Button.new()
		other_room_button.text = other_room.name
		other_room_button.button_down.connect(
			_on_other_room_button_down.bind(other_room)
			)
		other_rooms_holder.add_child(other_room_button)

func _on_other_room_button_down(other_room:Room) -> void:
	var current_connections:Array = current_room.passages[current_passage]
	var inText := " (already in)"
	var addText := " (to add)"
	var removeText:=" (to remove)"
	for child in selected_other_room_passages_holder.get_children():
		child.queue_free()
	for p in other_room.passages:
		var other_room_passage_button:=Button.new()
		other_room_passage_button.text = p
		var connection:= Connection.new()
		connection.room = other_room
		connection.connected_passage = p
		if(check_connection_array_has_element(connections_to_remove[current_passage], connection)):
			other_room_passage_button.text += removeText
		elif(check_connection_array_has_element(connections_to_add[current_passage], connection)):
			other_room_passage_button.text += addText
		elif(check_connection_array_has_element(current_connections,connection)):
			other_room_passage_button.text += inText
		
		other_room_passage_button.button_down.connect(
			_on_other_room_passage_button_down.bind(connection,other_room_passage_button)
			)
		selected_other_room_passages_holder.add_child(other_room_passage_button)

func _on_other_room_passage_button_down(connection: Connection, other_room_passage_button:Button) -> void:
	var current_connections:Array = current_room.passages[current_passage]
	var conn_remove_array:Array = connections_to_remove[current_passage]
	var conn_add_array:Array = connections_to_add[current_passage]
	var inText := " (already in)"
	var addText := " (to add)"
	var removeText:=" (to remove)"
	#checks if connection is already in
	if check_connection_array_has_element(current_connections,connection): 
		#if connection is to be removed, deletes connection from the removing array
		if delete_connection_from_array(conn_remove_array,connection):
			other_room_passage_button.text = connection.connected_passage+inText
			return
		#if connection wasn't removed from the removing array, add connection to removing array
		connections_to_remove[current_passage].append(connection)
		other_room_passage_button.text = connection.connected_passage+removeText
		return
	#if connection in the to add array, delete connection from to add array
	if delete_connection_from_array(conn_add_array,connection):
		other_room_passage_button.text = connection.connected_passage
		return
	#if none of the above were true, then the connection should be added to the to add array
	connections_to_add[current_passage].append(connection)
	other_room_passage_button.text += addText

func _on_scene_selected(path: String) -> void:
	current_room.scene_uid = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(path))
	scene_path_label.text = path
	if(current_room.name.is_empty()):
		if(path.ends_with(".tscn")):
			current_room.name = path.get_file().trim_suffix(".tscn")
		else:
			current_room.name = path.get_file().trim_suffix(".scn")
		room_name_input.text=current_room.name
	set_passages_from_scene()

func _on_room_name_changed() -> void:
	current_room.name = room_name_input.text

func _on_required_toggled(toggled_on: bool) -> void:
	current_room.required = toggled_on
	if(current_room.required==true):
		current_room.max_passes = 1
		max_passes_input.editable=false
		max_passes_input.value = current_room.max_passes
	else:
		max_passes_input.editable=true

func _on_max_passes_value_changed(value: float) -> void:
	current_room.max_passes = value

func _on_save_room_button() -> void:
	#TODO: add Data validation
	if(current_room.name==""):
		printerr("The room must have a name")
		return
	match current_state:
		State.CREATE:
			if(RogueSys.get_room_by_name(current_room.name) != null):
				printerr("Room name must be unique")
				return
			RogueSys.add_new_room(current_room, connections_to_add)
		State.UPDATE:
			RogueSys.update_room(current_room, room_old_name, connections_to_add, connections_to_remove)
	rooms_changed.emit()


func _on_adjacency_selection_close_requested() -> void:
	current_passage =""
	adjacency_selection.hide()

func _on_confirm_passages_button_down() -> void:
	update_passages()
	_on_adjacency_selection_close_requested()
	
func _on_delete_room_confirmation_confirmed() -> void:
	current_room.name = room_old_name
	RogueSys.delete_room(current_room)
	rooms_changed.emit()
