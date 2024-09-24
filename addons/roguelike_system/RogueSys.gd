@tool
extends EditorPlugin

const MainPanel = preload("res://addons/roguelike_system/nodes/MainPanel.tscn")
var main_panel_instance

func _enter_tree():
	main_panel_instance = MainPanel.instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	add_autoload_singleton("RogueSys", "res://addons/roguelike_system/scripts/RogueSysSingleton.gd")
	_make_visible(false)
	RogueSys.load_user_settings()
	SaveLoadData.load_plugin_data(RogueSys.get_current_map_path())
	RogueSys.finished_loading_plugin_data.emit()
	#see how to restart the project whenever the plugin is activated
	#OS.set_restart_on_exit(true)


func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func _get_plugin_name():
	return "Roguelike System"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")

func _save_external_data() -> void:
	SaveLoadData.save_plugin_data(RogueSys.get_current_map_path())
	RogueSys.save_user_settings()
