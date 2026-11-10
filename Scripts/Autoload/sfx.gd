extends Node

# Each sound picks one of its variants at random
const STREAMS := {
	&"enemy_hit": [
		preload("res://Assets/Team Godot Asset Folder/Audio/SFX/EnemyHit1.ogg"),
		preload("res://Assets/Team Godot Asset Folder/Audio/SFX/EnemyHit2.ogg"),
		preload("res://Assets/Team Godot Asset Folder/Audio/SFX/EnemyHit3.ogg"),
	],
	&"player_hit": [
		preload("res://Assets/Team Godot Asset Folder/Audio/SFX/PlayerHit1.ogg"),
		preload("res://Assets/Team Godot Asset Folder/Audio/SFX/PlayerHit2.ogg"),
		preload("res://Assets/Team Godot Asset Folder/Audio/SFX/PlayerHit3.ogg"),
	],
	&"jump": [preload("res://Assets/Team Godot Asset Folder/Audio/SFX/Jump.ogg")],
	&"drop": [preload("res://Assets/Team Godot Asset Folder/Audio/SFX/KeyDrop.ogg")],
	&"slash": [preload("res://Assets/Team Godot Asset Folder/Audio/SFX/Sword Slash.ogg")],
	&"upgrade": [preload("res://Assets/Team Godot Asset Folder/Audio/SFX/UpgradeRumble.ogg")],
}
const POOL_SIZE := 8  # sounds that can overlap

var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: StringName) -> void:
	var player := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = (STREAMS[sound] as Array).pick_random()
	player.play()
