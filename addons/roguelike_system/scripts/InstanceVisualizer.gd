@tool
extends VBoxContainer

@onready var export_data_selection: FileDialog = $ExportDataSelection
@onready var seed_input: SpinBox = $HBoxContainer/SeedInput

var path:String

func _on_export_data_selection_button_button_down() -> void:
	export_data_selection.popup_centered_ratio(0.5)



func _on_generate_button_button_down() -> void:
	pass # Replace with function body.
