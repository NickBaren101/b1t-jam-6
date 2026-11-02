extends CharacterBody2D

const GRAVITY := 900.0
const WALK_SPEED := 70.0
const CLIMB_SPEED := 55.0
const CLIMB_CENTER_PULL := 320.0
const CLIMB_CENTER_GAIN := 8.0
const SHOOT_COOLDOWN := 0.35
const INVULN_DURATION := 0.8
const FLICKER_INTERVAL := 0.08

const PLATFORM_MASK_BIT := 5

@export var bullet_scene: PackedScene

var facing := 1

var _climbing := false
var _platform_mask_cleared := false
var _shoot_timer := 0.0
var _invuln_timer := 0.0

@onready var visual: ColorRect = $Visual
@onready var muzzle: Marker2D = $Muzzle
@onready var platform_probe: Area2D = $PlatformProbe
@onready var health: HealthComponent = $HealthComponent

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	var shrine := get_tree().get_first_node_in_group(&"shrine") as Shrine
	_update_climb_state(shrine)
	if _climbing:
		_climb_motion(delta, shrine)
	else:
		_ground_motion(delta)
	move_and_slide()
	_restore_platform_mask()
	_update_facing()
	_update_flicker()

func _tick_timers(delta: float) -> void:
	_shoot_timer = maxf(_shoot_timer - delta, 0.0)
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)

func _update_climb_state(shrine: Shrine) -> void:
	var axis := Input.get_axis(&"move_up", &"move_down")
	var in_column := shrine != null and shrine.climb_rect().has_point(global_position)
	var wants_climb := in_column and not is_zero_approx(axis)
	if wants_climb == _climbing:
		return
	_climbing = wants_climb
	if _climbing:
		set_collision_mask_value(PLATFORM_MASK_BIT, false)
		_platform_mask_cleared = true
		velocity.y = 0.0

func _climb_motion(delta: float, shrine: Shrine) -> void:
	var column: Rect2 = shrine.climb_rect()
	velocity.y = Input.get_axis(&"move_up", &"move_down") * CLIMB_SPEED
	if global_position.y <= shrine.climb_top_y() and velocity.y < 0.0:
		velocity.y = 0.0
	var pull := (column.get_center().x - global_position.x) * CLIMB_CENTER_GAIN
	velocity.x = move_toward(velocity.x, pull, CLIMB_CENTER_PULL * delta)

func _ground_motion(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var dir := Input.get_axis(&"move_left", &"move_right")
	velocity.x = dir * WALK_SPEED * Favour.speed_mult()
	if Input.is_action_pressed(&"shoot") and _shoot_timer <= 0.0:
		_fire()

func _restore_platform_mask() -> void:
	if not _platform_mask_cleared or _climbing:
		return
	if not platform_probe.get_overlapping_bodies().is_empty():
		return
	set_collision_mask_value(PLATFORM_MASK_BIT, true)
	_platform_mask_cleared = false

func _update_facing() -> void:
	if _climbing:
		return
	if velocity.x > 0.0:
		facing = 1
	elif velocity.x < 0.0:
		facing = -1

func _update_flicker() -> void:
	if _invuln_timer <= 0.0:
		visual.visible = true
		return
	visual.visible = int(_invuln_timer / FLICKER_INTERVAL) % 2 == 0

func _fire() -> void:
	if bullet_scene == null:
		return
	_shoot_timer = SHOOT_COOLDOWN / maxf(Favour.fire_rate_mult(), 0.01)
	var bullet := bullet_scene.instantiate()
	var offset := muzzle.position
	offset.x = absf(offset.x) * facing
	bullet.direction = Vector2(facing, 0)
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + offset

func take_damage(amount: int) -> void:
	if _invuln_timer > 0.0:
		return
	_invuln_timer = INVULN_DURATION
	health.take_damage(amount)
