@tool
extends Control
@onready var room_details: HBoxContainer = $"TabContainer/Room Details"
@onready var possibilities_graph: HBoxContainer = $"TabContainer/Possibilities Graph"
@onready var levels_manager: MarginContainer = $"TabContainer/Levels Manager"
@onready var tab_container: TabContainer = $TabContainer
@onready var plugin_settings: MarginContainer = $"TabContainer/Plugin Settings"

func _ready() -> void:
	RogueSys.finished_loading_plugin_data.connect(fill_children_data)

func _on_tab_container_tab_changed(tab: int) -> void:
	if tab_container.get_current_tab_control()==room_details:
		room_details.on_rooms_changed()
	elif tab_container.get_current_tab_control()==possibilities_graph:
		possibilities_graph.fill_possibilities_graph()
	elif tab_container.get_current_tab_control()==levels_manager:
		levels_manager.fill_levels_manager_fields()
	elif tab_container.get_current_tab_control()==plugin_settings:
		plugin_settings.display_current_values()

func fill_children_data() -> void:
	room_details.fill_rooms_list()
	possibilities_graph.fill_possibilities_graph()
	levels_manager.fill_levels_manager_fields()
