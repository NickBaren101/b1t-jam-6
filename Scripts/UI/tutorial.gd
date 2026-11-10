class_name Tutorial
extends CanvasLayer

# Set by the story screen; consumed by the game scene, so retries after a game over skip it
static var pending := false

var _armed := false  # a key went down while open; the game resumes on its release

func _ready() -> void:
	visible = false
	if pending:
		pending = false
		visible = true
		get_tree().paused = true

# Resuming on release means the key that closes this doesn't also jump or attack
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var is_button := event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	if not is_button or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if event.is_pressed():
		_armed = true
	elif _armed:
		visible = false
		get_tree().paused = false
