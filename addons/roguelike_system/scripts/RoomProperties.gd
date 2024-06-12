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
@onready var other_rooms_holder: VBoxContainer = $ScrollContainer/VBoxContainer/MaxPasses/AdjacencySelection/Background/SelectionContainer/MainContent/OtherRoomsHolder
@onready var selected_other_room_passages_holder: VBoxContainer = $ScrollContainer/VBoxContainer/MaxPasses/AdjacencySelection/Background/SelectionContainer/MainContent/SelectedOtherRoomPassagesHolder
enum State {CREATE, UPDATE}
var current_state:State
var current_room:Room;
var room_old_name:String;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_new_empty_room()

func create_new_empty_room() -> void:
	current_state = State.CREATE
	current_room = Room.new()
	current_room.max_passes = 1
	current_room.required = false
	room_old_name = ""
	fill_interface()
	
func retrieve_existing_room(room_name:String) -> void:
	current_state = State.UPDATE
	var room := RogueSys.get_room_by_name(room_name)
	room_old_name = room.name
	current_room = room
	fill_interface()
	
func fill_interface() -> void:
	if(current_room.scene_uid.is_empty()):
		scene_path_label.text = ""
	else:
		scene_path_label.text = ResourceUID.get_id_path(ResourceUID.text_to_id(current_room.scene_uid))
	room_name_input.text = current_room.name
	max_passes_input.value = current_room.max_passes
	required_button.set_pressed_no_signal(current_room.required)
	update_passages()

#func print_current_room() -> void:
	#print(current_room.name)
	#print(current_room.scene_uid)
	#print(current_room.required)
	#print(current_room.max_passes)
	#for p in current_room.passages:
		#print(p+" = "+str(current_room.passages[p]))

func set_passages_from_scene() -> void:
	if(current_room.scene_uid.is_empty()):
		printerr("Scene hasn't been selected yet")
		return
	var scene_loaded := ResourceLoader.load(current_room.scene_uid)
	if !scene_loaded:
		printerr("Error loading resource")
		return
	var scene_instance = scene_loaded.instantiate()
	if(!scene_instance):
		printerr("Error instancing scene")
		return
	var passages_node = scene_instance.get_node("passages")
	if(!passages_node):
		passages_node = scene_instance.get_node("Passages")
		if(!passages_node):
			printerr("There must be a node on the scene, direct child of root, named passages or Passages")
			return
	var passage_children = passages_node.get_children()
	#TODO: make reading passages and assigning them better
	#ways to improve:
	#- reuse the old connections if a name remains the same
	#- if a passage name changes but it already had connections their connections are updated
	#Point to think about:if there is a failure in reading the new passages, should the old ones be brought back?
	current_room.passages = {}
	for p in passage_children:
		print(p.name)
		if(current_room.passages.has(p.name)):
			printerr("There is more than one passage with the same name")
			current_room.passages = {}
			return
		current_room.passages[p.name]=[]
	update_passages()
	
func update_passages()->void:
	for p in passages_holder.get_children():
		p.queue_free()
	for p in current_room.passages:
		var passage_container:= VBoxContainer.new()
		var name_and_button_container := HBoxContainer.new()
		passage_container.add_child(name_and_button_container)
		var passage_name := Label.new()
		passage_name.text ="- "+ p
		name_and_button_container.add_child(passage_name)
		var passage_button := Button.new()
		passage_button.text = "Change adjacencies"
		passage_button.button_down.connect(_on_passage_button_down.bind(p))
		name_and_button_container.add_child(passage_button)
		var possibilies_text := RichTextLabel.new()
		for possibility in current_room.passages[p]:
			possibilies_text.append_text("|- " + possibility)
		passage_container.add_child(possibilies_text)
		var separator:= HSeparator.new()
		passage_container.add_child(separator)
		passages_holder.add_child(passage_container)

func _on_passage_button_down(curr_passage:String):
	adjacency_selection.popup_centered_ratio(0.5)
	for other_room_name in RogueSys.get_rooms():
		var other_room: Room = RogueSys.get_room_by_name(other_room_name)
		if(other_room.name == current_room.name):
			continue
		var other_room_button := Button.new()
		other_room_button.text = other_room.name
		#other_room_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
		other_room_button.button_down.connect(_on_other_room_button_down.bind(other_room))
		other_rooms_holder.add_child(other_room_button)
		
func _on_other_room_button_down(otherRoom:Room):
	for p in otherRoom.passages:
		var passage_button:=Button.new()
		passage_button.text = p
		#passage_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
		selected_other_room_passages_holder.add_child(passage_button)

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
			RogueSys.add_new_room(current_room)
		State.UPDATE:
			RogueSys.update_room(current_room,room_old_name)
	rooms_changed.emit()
	create_new_empty_room()


func _on_adjacency_selection_close_requested() -> void:
	adjacency_selection.hide()
