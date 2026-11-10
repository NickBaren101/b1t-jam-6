extends Node2D

signal wave_started(index: int)
signal wave_cleared(index: int)  # spawn window over and every wave enemy dead
signal boss_started(moon: Moon)
signal boss_defeated

# duration: s of spawning; interval goes from interval_start to interval_min over it.
# Flyer lanes = wave index, which matches the platforms the shrine has revealed by then.
const WAVES: Array[Dictionary] = [
	{duration = 30.0, interval_start = 2.0, interval_min = 1.2, flyer_chance = 0.0},
	{duration = 35.0, interval_start = 1.6, interval_min = 0.9, flyer_chance = 0.35},
	{duration = 40.0, interval_start = 1.3, interval_min = 0.6, flyer_chance = 0.45},
]
const BALANCE_DEADBAND := 2
const MAX_ALIVE := 24
const SPAWN_X: Array[float] = [-16.0, 496.0]
const BOSS_SPAWN_SPREAD := 12.0   # px between walkers from one asteroid
const BOSS_SPAWN_MIN_X := 8.0
const BOSS_SPAWN_MAX_X := 472.0

@export var walker_scene: PackedScene
@export var flyer_scene: PackedScene
@export var moon_scene: PackedScene

var _side_counts: Array[int] = [0, 0]
var _wave := -1
var _wave_active := false
var _wave_time := 0.0
var _timer := 0.0

func start_wave(index: int) -> void:
	_wave = index
	_wave_active = true
	_wave_time = 0.0
	_timer = WAVES[index].interval_start
	wave_started.emit(index)

func _process(delta: float) -> void:
	if not _wave_active:
		return
	var wave: Dictionary = WAVES[_wave]
	if _wave_time >= wave.duration:
		if _side_counts[0] + _side_counts[1] == 0:
			_wave_active = false
			wave_cleared.emit(_wave)
		return
	_wave_time += delta
	_timer -= delta
	if _timer > 0.0:
		return
	_spawn(wave)
	_timer = lerpf(wave.interval_start, wave.interval_min, minf(_wave_time / wave.duration, 1.0))

func _pick_side() -> int:
	var diff := _side_counts[0] - _side_counts[1]
	if absi(diff) < BALANCE_DEADBAND:
		return randi() % 2
	return 1 if diff > 0 else 0

func _spawn(wave: Dictionary) -> void:
	if _side_counts[0] + _side_counts[1] >= MAX_ALIVE:
		return
	var side := _pick_side()
	var lanes := _wave
	var use_flyer: bool = lanes > 0 and randf() < float(wave.flyer_chance)
	var lane := 0
	if use_flyer:
		lane = randi() % lanes
		if Flyer.is_queue_full(side, lane):
			use_flyer = false
	var enemy: Enemy = (flyer_scene if use_flyer else walker_scene).instantiate()
	var spawn_y := Tiers.stand_center_y(Tiers.GROUND_SURFACE_Y, Tiers.WALKER_HALF_H)
	if use_flyer:
		enemy.set(&"lane", lane)
		spawn_y = Tiers.lane_y(lane)
	_add_enemy(enemy, side, Vector2(SPAWN_X[side], spawn_y))

func _add_enemy(enemy: Enemy, side: int, pos: Vector2) -> void:
	enemy.tree_exited.connect(_on_enemy_gone.bind(side))
	_side_counts[side] += 1
	add_child(enemy)
	enemy.global_position = pos

func _on_enemy_gone(side: int) -> void:
	_side_counts[side] -= 1

# ---------- Moon boss ----------

func start_boss() -> void:
	if moon_scene == null:
		return
	var moon: Moon = moon_scene.instantiate()
	moon.spawner = self
	moon.defeated.connect(boss_defeated.emit)
	add_child(moon)
	moon.start_at_corner(randi() % 2)
	boss_started.emit(moon)

# Called by asteroids hitting the ground, ignores MAX_ALIVE
func spawn_walkers_at(x: float, count: int) -> void:
	var y := Tiers.stand_center_y(Tiers.GROUND_SURFACE_Y, Tiers.WALKER_HALF_H)
	# Shift the whole group inward so it fits on screen without stacking at the edge
	var half := (count - 1) * 0.5 * BOSS_SPAWN_SPREAD
	var center := clampf(x, BOSS_SPAWN_MIN_X + half, BOSS_SPAWN_MAX_X - half)
	for i in count:
		var spawn_x := center + (i - (count - 1) * 0.5) * BOSS_SPAWN_SPREAD
		var side := 0 if spawn_x < Tiers.CENTER_X else 1
		var walker: Enemy = walker_scene.instantiate()
		_add_enemy(walker, side, Vector2(spawn_x, y))
