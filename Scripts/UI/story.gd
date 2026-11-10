extends Control

const GAME_SCENE := "res://Scenes/Main/main.tscn"
const CHARS_PER_SECOND := 40.0
const LINE_PAUSE := 0.7   # s between lines
const END_HOLD := 2.5     # s the full text stays up before the game starts

# Edit the lore here or in the inspector; each entry types out as its own line
@export_multiline var lines: Array[String] = [
	"Once in a hundred years, the Blood Moon wakes above the mountain shrine.",
	"Its light drags the dead from their graves: jiangshi and ghouls that walk, bats and spirits that fly.",
	"Only Jinsha, last guardian of the shrine, stands between them and the temple.",
]

var _leaving := false

@onready var text: Label = %Text

# Plays on its own: every line types out in turn, then the game starts
func _ready() -> void:
	text.text = "\n\n".join(lines)
	text.visible_characters = 0
	var tween := create_tween()
	var shown := 0
	for i in lines.size():
		var end := shown + lines[i].length()
		tween.tween_property(text, ^"visible_characters", end, lines[i].length() / CHARS_PER_SECOND)
		tween.tween_interval(END_HOLD if i == lines.size() - 1 else LINE_PAUSE)
		shown = end + 2  # the "\n\n" between lines
	tween.tween_callback(_start_game)

# Any key or click skips straight to the game
func _unhandled_input(event: InputEvent) -> void:
	var is_button := event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	if is_button and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_start_game()

func _start_game() -> void:
	if _leaving:
		return
	_leaving = true
	Tutorial.pending = true
	get_tree().change_scene_to_file(GAME_SCENE)
