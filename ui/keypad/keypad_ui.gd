class_name KeypadUI
extends Control

signal correct_code_entered

@export_group("Keypad Settings")
@export var wrong_code_color := Color.RED
@export var correct_code_color := Color.GREEN
@export var unlock_wait_time := 1.0
@export var correct_code_entered_sound: AudioStream
@export var wrong_code_entered_sound: AudioStream

@onready var lock_color: TextureRect = $PanelContainer/VBoxContainer/PanelContainer/HBoxContainer/LockColor
@onready var code_display: Label = $PanelContainer/VBoxContainer/PanelContainer/HBoxContainer/CodeDisplay
@onready var grab_focus_button: Button = $"PanelContainer/VBoxContainer/GridContainer/5"

var passcode: String

var _entered_code: String


func _ready() -> void:
	_clear_entered_code()
	grab_focus_button.grab_focus()


func _clear_entered_code() -> void:
	_entered_code = ""
	code_display.text = ""


func _append_to_entered_code(code_digit: String) -> void:
	if _entered_code.length() < passcode.length():
		_entered_code = _entered_code + code_digit
		_update_code_display()

	if _entered_code.length() >= passcode.length():
		_check_entered_code()


func _update_code_display() -> void:
	code_display.text = _entered_code


func _check_entered_code() -> void:
	if _entered_code == passcode:
		AudioManager.play_ui_sound(correct_code_entered_sound)
		lock_color.modulate = correct_code_color
		await get_tree().create_timer(unlock_wait_time).timeout
		correct_code_entered.emit()
	else:
		AudioManager.play_ui_sound(wrong_code_entered_sound)
		lock_color.modulate = wrong_code_color
		await get_tree().create_timer(unlock_wait_time).timeout
		_clear_entered_code()
