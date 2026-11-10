extends Node2D

signal boss_defeated

const SPAWN_INTERVAL_START := 2.2
const SPAWN_INTERVAL_MIN := 0.45
const SPAWN_INTERVAL_DECAY := 0.97
const BALANCE_DEADBAND := 2
const MAX_ALIVE := 24
const FLYER_CHANCE := 0.45
const SPAWN_X: Array[float] = [-16.0, 336.0]
const BOSS_DELAY := 20.0          # s after the last shrine tier unlocks
const BOSS_SPAWN_SPREAD := 12.0   # px between walkers from one asteroid
const BOSS_SPAWN_MIN_X := 8.0
const BOSS_SPAWN_MAX_X := 312.0

@export var walker_scene: PackedScene
@export var flyer_scene: PackedScene
@export var moon_scene: PackedScene

var _side_counts: Array[int] = [0, 0]
var _interval := SPAWN_INTERVAL_START
var _timer := SPAWN_INTERVAL_START
var _boss_timer := -1.0
var _boss_pending := false  # timer done, waiting for every enemy to be killed
var _boss_active := false

func _ready() -> void:
	Favour.tier_unlocked.connect(_on_tier_unlocked)

func _process(delta: float) -> void:
	if _boss_timer > 0.0:
		_boss_timer -= delta
		if _boss_timer <= 0.0:
			_boss_pending = true
	if _boss_pending and _side_counts[0] + _side_counts[1] == 0:
		_boss_pending = false
		_spawn_boss()
	if _boss_pending or _boss_active:
		return  # regular spawns stop so the screen can be cleared, and stay off during the boss
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
	var lane := 0
	if use_flyer:
		lane = randi() % Favour.unlocked_tiers
		if Flyer.is_queue_full(side, lane):
			use_flyer = false
	var enemy: Enemy = (flyer_scene if use_flyer else walker_scene).instantiate()
	var spawn_y := Tiers.stand_center_y(Tiers.GROUND_SURFACE_Y, Tiers.WALKER_HALF_H)
	if use_flyer:
		enemy.set(&"lane", lane)
		spawn_y = Tiers.lane_y(lane)
	_add_enemy(enemy, side, Vector2(SPAWN_X[side], spawn_y))
	_interval = maxf(_interval * SPAWN_INTERVAL_DECAY, SPAWN_INTERVAL_MIN)

func _add_enemy(enemy: Enemy, side: int, pos: Vector2) -> void:
	enemy.tree_exited.connect(_on_enemy_gone.bind(side))
	_side_counts[side] += 1
	add_child(enemy)
	enemy.global_position = pos

func _on_enemy_gone(side: int) -> void:
	_side_counts[side] -= 1

# ---------- Moon boss ----------

func _on_tier_unlocked(index: int) -> void:
	if index == Tiers.SURFACE_Y.size() - 1 and not _boss_active and not _boss_pending:
		_boss_timer = BOSS_DELAY

func _spawn_boss() -> void:
	if moon_scene == null:
		return
	_boss_active = true
	var moon: Moon = moon_scene.instantiate()
	moon.spawner = self
	moon.defeated.connect(boss_defeated.emit)
	add_child(moon)
	moon.start_at_corner(randi() % 2)

# Called by asteroids hitting the ground, ignores MAX_ALIVE
func spawn_walkers_at(x: float, count: int) -> void:
	var y := Tiers.stand_center_y(Tiers.GROUND_SURFACE_Y, Tiers.WALKER_HALF_H)
	for i in count:
		var offset := (i - (count - 1) * 0.5) * BOSS_SPAWN_SPREAD
		var spawn_x := clampf(x + offset, BOSS_SPAWN_MIN_X, BOSS_SPAWN_MAX_X)
		var side := 0 if spawn_x < Tiers.CENTER_X else 1
		var walker: Enemy = walker_scene.instantiate()
		_add_enemy(walker, side, Vector2(spawn_x, y))
