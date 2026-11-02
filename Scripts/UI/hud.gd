extends CanvasLayer

var _ended := false

@onready var shrine_label: Label = $ShrineLabel
@onready var player_label: Label = $PlayerLabel
@onready var favour_label: Label = $FavourLabel
@onready var message_label: Label = $MessageLabel

func _ready() -> void:
	Favour.favour_changed.connect(_on_favour_changed)
	_on_favour_changed(Favour.favour)

func _unhandled_input(event: InputEvent) -> void:
	if not _ended:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_tree().paused = false
		get_tree().call_deferred("reload_current_scene")

func set_shrine_health(current: int, maximum: int) -> void:
	shrine_label.text = "SHRINE %d/%d" % [current, maximum]

func set_player_health(current: int, maximum: int) -> void:
	player_label.text = "JINSHA %d/%d" % [current, maximum]

func show_run_end(message: String) -> void:
	if _ended:
		return
	_ended = true
	message_label.text = "%s\nPRESS ANY KEY" % message
	message_label.visible = true
	get_tree().paused = true

func _on_favour_changed(value: int) -> void:
	favour_label.text = "FAVOUR %d   TIERS %d" % [value, Favour.unlocked_tiers]
