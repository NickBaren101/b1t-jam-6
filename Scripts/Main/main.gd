extends Node2D

@export var boss_music: AudioStream

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
	$Spawner.boss_defeated.connect(_on_run_ended.bind("THE MOON HAS FALLEN"))
	$Spawner.boss_started.connect(_on_boss_started)
	hud.set_shrine_health(shrine_health.current_health, shrine_health.max_health)
	hud.set_player_health(player_health.current_health, player_health.max_health)

func _on_boss_started() -> void:
	if boss_music != null:
		music.stream = boss_music
		music.play()

func _on_run_ended(message: String) -> void:
	hud.show_run_end(message)
