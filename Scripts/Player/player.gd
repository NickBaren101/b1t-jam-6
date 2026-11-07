extends CharacterBody2D

const WALK_SPEED := 70.0
const SHOOT_COOLDOWN := 0.35
const INVULN_DURATION := 0.8
const FLICKER_INTERVAL := 0.08

# --- Jump: gravity and jump speed are derived from OVERSHOOT and FALL_TIME ---
const OVERSHOOT := 10.0       # px the feet end up ABOVE the platform surface at the apex
const FALL_TIME := 0.35       # s from the apex down to the platform surface
const MAX_FALL_SPEED := 300.0
const AIR_ACCEL := 40.0       # px/s², only slight steering in the air
const AIR_SHOTS := 1          # shots allowed while airborne
const DROP_START_SPEED := 30.0
const DROP_MIN_TIME := 0.1

const PLATFORM_MASK_BIT := 5

@export var bullet_scene: PackedScene

var facing := 1

var _gravity := 0.0
var _jump_speed := 0.0
var _dropping := false
var _drop_time := 0.0
var _air_shots_left := AIR_SHOTS
var _shoot_timer := 0.0
var _invuln_timer := 0.0

@onready var visual: ColorRect = $Visual
@onready var muzzle: Marker2D = $Muzzle
@onready var health: HealthComponent = $HealthComponent
@onready var _shape_node: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var rise := Tiers.GROUND_SURFACE_Y - Tiers.SURFACE_Y[0]  # 42 px between platform levels
	_gravity = 2.0 * OVERSHOOT / (FALL_TIME * FALL_TIME)
	_jump_speed = sqrt(2.0 * _gravity * (rise + OVERSHOOT))

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_update_drop(delta)
	_motion(delta)
	move_and_slide()
	if is_on_floor():
		_air_shots_left = AIR_SHOTS
	_update_facing()
	_update_flicker()

func _tick_timers(delta: float) -> void:
	_shoot_timer = maxf(_shoot_timer - delta, 0.0)
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)

func _motion(delta: float) -> void:
	var max_speed := WALK_SPEED * Favour.speed_mult()
	var dir := Input.get_axis(&"move_left", &"move_right")

	if is_on_floor():
		velocity.x = dir * max_speed
		if Input.is_action_just_pressed(&"move_up") and _can_jump():
			velocity.y = -_jump_speed
		elif Input.is_action_just_pressed(&"move_down") and _standing_on_platform():
			_begin_drop()
	else:
		# Takeoff speed is kept: parabola when moving, straight drop when standing still
		velocity.x = clampf(velocity.x + dir * AIR_ACCEL * delta, -max_speed, max_speed)
		velocity.y = minf(velocity.y + _gravity * delta, MAX_FALL_SPEED)

	if Input.is_action_pressed(&"shoot") and _shoot_timer <= 0.0 and _can_shoot():
		_fire()

# ---------- Jump ----------

func _can_jump() -> bool:
	# Only called while on the floor, so no double jump is possible
	if _standing_on_platform():
		return true
	var shrine := get_tree().get_first_node_in_group(&"shrine") as Shrine
	return shrine != null and shrine.climb_rect().has_point(global_position)

# ---------- Dropping through platforms ----------

func _begin_drop() -> void:
	_dropping = true
	_drop_time = 0.0
	set_collision_mask_value(PLATFORM_MASK_BIT, false)  # platforms stop being solid
	velocity.y = DROP_START_SPEED

func _update_drop(delta: float) -> void:
	if not _dropping:
		return
	_drop_time += delta
	if _drop_time < DROP_MIN_TIME:
		return
	var released := not Input.is_action_pressed(&"move_down")
	var landed := is_on_floor()  # with platforms off, this can only be the ground
	# Platforms turn solid again only once the player is completely out of them
	if (released or landed) and not _overlaps_platform():
		_dropping = false
		set_collision_mask_value(PLATFORM_MASK_BIT, true)

func _standing_on_platform() -> bool:
	return is_on_floor() and _query_platform(Vector2(0.0, 2.0))

func _overlaps_platform() -> bool:
	return _query_platform(Vector2.ZERO)

func _query_platform(offset: Vector2) -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = _shape_node.shape
	params.transform = _shape_node.global_transform.translated(offset)
	params.collision_mask = 1 << (PLATFORM_MASK_BIT - 1)
	params.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(params, 1).is_empty()

# ---------- Shooting ----------

func _can_shoot() -> bool:
	return is_on_floor() or _air_shots_left > 0

func _fire() -> void:
	if bullet_scene == null:
		return
	_shoot_timer = SHOOT_COOLDOWN / maxf(Favour.fire_rate_mult(), 0.01)
	if not is_on_floor():
		_air_shots_left -= 1
	var bullet := bullet_scene.instantiate()
	var offset := muzzle.position
	offset.x = absf(offset.x) * facing
	bullet.direction = Vector2(facing, 0)
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + offset

# ---------- Unchanged ----------

func _update_facing() -> void:
	if velocity.x > 0.0:
		facing = 1
	elif velocity.x < 0.0:
		facing = -1

func _update_flicker() -> void:
	if _invuln_timer <= 0.0:
		visual.visible = true
		return
	visual.visible = int(_invuln_timer / FLICKER_INTERVAL) % 2 == 0

func take_damage(amount: int) -> void:
	if _invuln_timer > 0.0:
		return
	_invuln_timer = INVULN_DURATION
	health.take_damage(amount)
