@tool
extends MarginContainer
@onready var map_file_dialog: FileDialog = $MapFileDialog
@onready var passages_holder_window: Window = $PassagesHolderWindow
@onready var save_current_map_dialog: ConfirmationDialog = $SaveCurrentMapDialog
@onready var popup_errors_toggle: CheckButton = $VBoxContainer/PopupErrorsToggle
@onready var current_map_file_path_label: Label = $VBoxContainer/CurrentMapFilePathLabel

enum Actions{CREATE, RENAME, LOAD}
var current_action:Actions
var map_path := ""

func display_current_values()->void:
	current_map_file_path_label.text = "Current map file path: \n"+RogueSys.get_current_map_path()
	popup_errors_toggle.set_pressed_no_signal(RogueSys.get_show_errors())

func create_new_map() -> void:
	if map_path == "":
		var message := "Path for new map empty."
		printerr(message)
		RogueSys.throw_error.emit(message)
	RogueSys.create_new_map(map_path)
	display_current_values()
	RogueSys.save_user_settings()

func new_map_dialog(path:String) -> void:
	map_path = path
	await get_tree().create_timer(0.1).timeout
	save_current_map_dialog.dialog_text = "Save current map before creating a new one?"
	save_current_map_dialog.popup_centered()

func load_map() -> void:
	if map_path == "":
		var message := "Path for map is empty."
		printerr(message)
		RogueSys.throw_error.emit(message)
		return
	if SaveLoadData.load_plugin_data(map_path):
		RogueSys.set_current_map_path(map_path)
		display_current_values()
		RogueSys.save_user_settings()

func load_map_dialog(path:String) -> void:
	map_path = path
	await get_tree().create_timer(0.1).timeout
	save_current_map_dialog.dialog_text = "Save current map before loading another?"
	save_current_map_dialog.popup_centered()

func rename_current_map(path:String) -> void:
	DirAccess.rename_absolute(RogueSys.get_current_map_path(), path)
	RogueSys.set_current_map_path(path)
	display_current_values()
	RogueSys.save_user_settings()

func _on_new_map_button_button_down() -> void:
	current_action = Actions.CREATE
	map_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	map_file_dialog.popup_centered_ratio(0.5)
	if DirAccess.dir_exists_absolute("res://addons/roguelike_system/save/"):
		map_file_dialog.current_path = "res://addons/roguelike_system/save/"

func _on_map_file_dialog_file_selected(path: String) -> void:
	match current_action:
		Actions.CREATE:
			new_map_dialog(path)
		Actions.RENAME:
			rename_current_map(path)
		Actions.LOAD:
			load_map_dialog(path)

func _on_save_current_map_dialog_confirmed() -> void:
	SaveLoadData.save_plugin_data(RogueSys.get_current_map_path())
	match current_action:
		Actions.CREATE:
			create_new_map()
		Actions.LOAD:
			load_map()

func _on_save_current_map_dialog_canceled() -> void:
	match current_action:
		Actions.CREATE:
			create_new_map()
		Actions.LOAD:
			load_map()

func _on_rename_map_button_button_down() -> void:
	current_action = Actions.RENAME
	map_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	map_file_dialog.popup_centered_ratio(0.5)
	map_file_dialog.current_path = RogueSys.get_current_map_path()


func _on_load_map_button_button_down() -> void:
	current_action = Actions.LOAD
	map_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	map_file_dialog.popup_centered_ratio(0.5)
	map_file_dialog.current_path = RogueSys.get_current_map_path()
	


func _on_popup_errors_toggle_toggled(toggled_on: bool) -> void:
	RogueSys.set_show_errors(toggled_on)
	display_current_values()
	RogueSys.save_user_settings()
