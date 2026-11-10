extends CanvasLayer

var _ended := false
var _wave_text := ""

@onready var shrine_label: Label = $ShrineLabel
@onready var player_label: Label = $PlayerLabel
@onready var favour_label: Label = $FavourLabel
@onready var message_label: Label = $MessageLabel
@onready var moon_bar: Control = $MoonBar
@onready var moon_fill: ColorRect = $MoonBar/Fill
@onready var _moon_fill_width := moon_fill.size.x

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

func show_moon_bar(moon_health: HealthComponent) -> void:
	moon_health.health_changed.connect(_set_moon_health)
	_set_moon_health(moon_health.current_health, moon_health.max_health)
	moon_bar.visible = true

func _set_moon_health(current: int, maximum: int) -> void:
	moon_fill.size.x = roundf(_moon_fill_width * current / maximum)
	moon_fill.visible = current > 0

func set_wave(text: String) -> void:
	_wave_text = text
	_on_favour_changed(Favour.favour)

func _on_favour_changed(value: int) -> void:
	favour_label.text = "FAVOUR %d   %s" % [value, _wave_text]
