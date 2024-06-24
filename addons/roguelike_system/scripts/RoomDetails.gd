@tool
extends HBoxContainer
@onready var room_properties: PanelContainer = $RoomProperties
@onready var rooms_container: VBoxContainer = $Container/ScrollContainer/List/RoomsContainer

#create a new scene that has a a button with the name of the room, connect all the buttons to this script with them passing their name when button_down
func _ready() -> void:
	fill_rooms_list()
	
func _on_new_room_button_down() -> void:
	room_properties.create_new_empty_room()

func _on_delete_room_button_down() -> void:
	room_properties.open_delete_current_room_dialog()

func _on_rooms_changed() -> void:
	fill_rooms_list()
	room_properties.create_new_empty_room()

func _on_room_selected(name:String) -> void:
	room_properties.retrieve_existing_room(name)

func fill_rooms_list() -> void:
	for r in rooms_container.get_children():
		r.queue_free()
	var rooms := RogueSys.get_rooms()
	print(rooms)
	for name in rooms:
		print(name)
		var button := Button.new()
		button.text = name
		button.button_down.connect(_on_room_selected.bind(button.text))
		rooms_container.add_child(button)
		
