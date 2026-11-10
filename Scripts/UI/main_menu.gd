extends Control

const STORY_SCENE := "res://Scenes/UI/story.tscn"

@onready var new_game: Button = %NewGame
@onready var exit_game: Button = %ExitGame

func _ready() -> void:
	new_game.pressed.connect(_on_new_game)
	exit_game.pressed.connect(get_tree().quit)
	exit_game.visible = not OS.has_feature("web")  # a browser tab can't be closed by the game
	for button: Button in [new_game, exit_game]:
		button.mouse_entered.connect(button.grab_focus)  # hover and keyboard share one highlight
	new_game.grab_focus()

func _on_new_game() -> void:
	get_tree().change_scene_to_file(STORY_SCENE)
