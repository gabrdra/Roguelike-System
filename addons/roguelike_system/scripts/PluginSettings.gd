@tool
extends MarginContainer
@onready var create_map_dialog: FileDialog = $CreateMapDialog
@onready var passages_holder_window: Window = $PassagesHolderWindow
@onready var save_current_map_dialog: ConfirmationDialog = $SaveCurrentMapDialog

enum Actions{CREATE, RENAME, OPEN}
var current_action:Actions
var map_path := ""
func create_new_map() -> void:
	if map_path == "":
		var message := "Path for new map empty."
		printerr(message)
		RogueSys.throw_error.emit(message)
	RogueSys.create_new_map(map_path)

func _on_new_map_button_button_down() -> void:
	current_action = Actions.CREATE
	create_map_dialog.popup_centered_ratio(0.5)
	if DirAccess.dir_exists_absolute("res://addons/roguelike_system/save/"):
		create_map_dialog.current_path = "res://addons/roguelike_system/save/"

func _on_create_map_dialog_file_selected(path: String) -> void:
	if FileAccess.file_exists(path):
		var message := "A file with the given name already exists";
		printerr(message)
		RogueSys.throw_error.emit(message)
		return
	map_path = path
	await get_tree().create_timer(0.1).timeout
	save_current_map_dialog.dialog_text = "Save current map before creating a new one?"
	save_current_map_dialog.popup_centered()

func _on_create_rename_level_window_close_requested() -> void:
	pass # Replace with function body.


func _on_confirm_button_button_down() -> void:
	pass # Replace with function body.


func _on_create_rename_input_text_changed() -> void:
	pass # Replace with function body.


func _on_save_current_map_dialog_confirmed() -> void:
	SaveLoadData.save_plugin_data(RogueSys.get_current_map_path())
	if current_action == Actions.CREATE:
		create_new_map()

func _on_save_current_map_dialog_canceled() -> void:
	if current_action == Actions.CREATE:
		create_new_map()
