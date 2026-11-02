extends Node2D

@onready var shrine_health: HealthComponent = $Shrine/HealthComponent
@onready var player_health: HealthComponent = $Player/HealthComponent
@onready var hud := $Hud

func _ready() -> void:
	Favour.reset()
	shrine_health.health_changed.connect(hud.set_shrine_health)
	player_health.health_changed.connect(hud.set_player_health)
	shrine_health.died.connect(_on_run_ended.bind("THE SHRINE HAS FALLEN"))
	player_health.died.connect(_on_run_ended.bind("JINSHA HAS FALLEN"))
	hud.set_shrine_health(shrine_health.current_health, shrine_health.max_health)
	hud.set_player_health(player_health.current_health, player_health.max_health)

func _on_run_ended(message: String) -> void:
	hud.show_run_end(message)
