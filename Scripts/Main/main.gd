extends Node2D

@export var boss_music: AudioStream
# Testing: skip the waves and start at the Moon. Ignored in release exports.
@export var debug_start_at_boss := false

@onready var spawner := $Spawner
@onready var shrine: Shrine = $Shrine
@onready var player := $Player
@onready var shrine_health: HealthComponent = $Shrine/HealthComponent
@onready var player_health: HealthComponent = $Player/HealthComponent
@onready var hud := $Hud
@onready var music: AudioStreamPlayer = $Music
#@onready var enemy := $enemyPath

func _ready() -> void:
	Favour.reset()
	Flyer.reset_queues() #new 06.11.2026
	shrine_health.health_changed.connect(hud.set_shrine_health)
	player_health.health_changed.connect(hud.set_player_health)
	shrine_health.died.connect(_on_run_ended.bind("THE SHRINE HAS FALLEN"))
	player_health.died.connect(_on_run_ended.bind("JINSHA HAS FALLEN"))
	spawner.boss_defeated.connect(_on_run_ended.bind("THE MOON HAS FALLEN"))
	spawner.boss_started.connect(_on_boss_started)
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_cleared.connect(_on_wave_cleared)
	hud.set_shrine_health(shrine_health.current_health, shrine_health.max_health)
	hud.set_player_health(player_health.current_health, player_health.max_health)
	if debug_start_at_boss and OS.is_debug_build():
		shrine.set_stage(Shrine.STAGE_OFFSET.size() - 1)
		spawner.start_boss()
	else:
		spawner.start_wave(0)

func _on_wave_started(index: int) -> void:
	hud.set_wave("WAVE %d/%d" % [index + 1, spawner.WAVES.size()])

# Every wave but the last raises the shrine to its next platform; the last one brings the Moon
func _on_wave_cleared(index: int) -> void:
	if index == spawner.WAVES.size() - 1:
		spawner.start_boss()
		return
	player.controls_enabled = false
	await shrine.rise()
	player.controls_enabled = true
	spawner.start_wave(index + 1)

func _on_boss_started(moon: Moon) -> void:
	hud.set_wave("MOON")
	hud.show_moon_bar(moon.health)
	if boss_music != null:
		music.stream = boss_music
		music.play()

func _on_run_ended(message: String) -> void:
	hud.show_run_end(message)
