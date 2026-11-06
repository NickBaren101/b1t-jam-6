extends Node2D

const SPAWN_INTERVAL_START := 2.2
const SPAWN_INTERVAL_MIN := 0.45
const SPAWN_INTERVAL_DECAY := 0.97
const BALANCE_DEADBAND := 2
const MAX_ALIVE := 24
const FLYER_CHANCE := 0.45
const SPAWN_X: Array[float] = [-16.0, 336.0]

@export var walker_scene: PackedScene
@export var flyer_scene: PackedScene

var _side_counts: Array[int] = [0, 0]
var _interval := SPAWN_INTERVAL_START
var _timer := SPAWN_INTERVAL_START

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_spawn()
	_timer = _interval

func _pick_side() -> int:
	var diff := _side_counts[0] - _side_counts[1]
	if absi(diff) < BALANCE_DEADBAND:
		return randi() % 2
	return 1 if diff > 0 else 0

func _spawn() -> void:
	if _side_counts[0] + _side_counts[1] >= MAX_ALIVE:
		return
	var side := _pick_side()
	var use_flyer := Favour.unlocked_tiers > 0 and randf() < FLYER_CHANCE
	var enemy: Enemy = (flyer_scene if use_flyer else walker_scene).instantiate()
	var spawn_y := Tiers.stand_center_y(Tiers.GROUND_SURFACE_Y, Tiers.WALKER_HALF_H)
	if use_flyer:
		var lane := randi() % Favour.unlocked_tiers
		enemy.set(&"lane", lane)
		spawn_y = Tiers.lane_y(lane)
	enemy.tree_exited.connect(_on_enemy_gone.bind(side))
	_side_counts[side] += 1
	add_child(enemy)
	enemy.global_position = Vector2(SPAWN_X[side], spawn_y)
	_interval = maxf(_interval * SPAWN_INTERVAL_DECAY, SPAWN_INTERVAL_MIN)

func _on_enemy_gone(side: int) -> void:
	_side_counts[side] -= 1
