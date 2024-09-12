@tool
extends MarginContainer
@onready var map_file_dialog: FileDialog = $MapFileDialog
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

func new_map_dialog(path:String) -> void:
	if FileAccess.file_exists(path):
		var message := "A file with the given name already exists";
		printerr(message)
		RogueSys.throw_error.emit(message)
		return
	map_path = path
	await get_tree().create_timer(0.1).timeout
	save_current_map_dialog.dialog_text = "Save current map before creating a new one?"
	save_current_map_dialog.popup_centered()

func rename_current_map(path:String) -> void:
	DirAccess.rename_absolute(RogueSys.get_current_map_path(), path)
	RogueSys.set_current_map_path(path)

func _on_new_map_button_button_down() -> void:
	current_action = Actions.CREATE
	map_file_dialog.popup_centered_ratio(0.5)
	if DirAccess.dir_exists_absolute("res://addons/roguelike_system/save/"):
		map_file_dialog.current_path = "res://addons/roguelike_system/save/"

func _on_map_file_dialog_file_selected(path: String) -> void:
	if current_action == Actions.CREATE:
		new_map_dialog(path)
	if current_action == Actions.RENAME:
		rename_current_map(path)

func _on_save_current_map_dialog_confirmed() -> void:
	SaveLoadData.save_plugin_data(RogueSys.get_current_map_path())
	if current_action == Actions.CREATE:
		create_new_map()

func _on_save_current_map_dialog_canceled() -> void:
	if current_action == Actions.CREATE:
		create_new_map()

func _on_rename_map_button_button_down() -> void:
	current_action = Actions.RENAME
	map_file_dialog.popup_centered_ratio(0.5)
	map_file_dialog.current_path = RogueSys.get_current_map_path()
