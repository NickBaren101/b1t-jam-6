class_name Moon
extends Enemy

# Emitted once it has fallen off screen
signal defeated

enum State { AIMING, TRAVELLING, FALLING }

const SHOT_WAIT := 4.0           # wait in a corner before shooting
const SHOT_WAIT_ENRAGED := 2.0   # same, at or below ENRAGE_FRACTION health
const ENRAGE_FRACTION := 0.25
const TELEGRAPH_TIME := 1.0      # last part of the wait, aim is locked here
const CONTACT_COOLDOWN := 0.8
const FALL_GRAVITY := 200.0
const OFFSCREEN_Y := 180.0
const ARRIVE_EPSILON := 0.5
const CORNER_X: Array[float] = [0.0, 320.0]
const TELEGRAPH_COLOR := Color(1.0, 0.3, 0.3)

@export var radius := 40.0        # centered on a corner, so only a quarter is visible
@export var center_y := 0.0
@export var travel_speed := 30.0
@export var contact_damage := 1
@export var asteroid_scene: PackedScene

var spawner: Node  # set by the spawner, turns asteroid landings into walkers

var _state := State.AIMING
var _corner := 0
var _shot_timer := 0.0
var _contact_timer := 0.0
var _aim_locked := false
var _aim_dir := Vector2.DOWN

@onready var contact_hitbox: Area2D = $ContactHitbox
@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	super._ready()
	# Body and ContactHitbox share this shape
	($CollisionShape2D.shape as CircleShape2D).radius = radius
	visual.scale = Vector2.ONE * radius * 2.0 / visual.region_rect.size.y
	_start_aiming()


func start_at_corner(corner: int) -> void:
	_corner = corner
	global_position = Vector2(CORNER_X[corner], center_y)
	_face_corner()


func _move(delta: float) -> void:
	match _state:
		State.AIMING:
			velocity = Vector2.ZERO
			_update_aiming(delta)
		State.TRAVELLING:
			var dx := CORNER_X[_corner] - global_position.x
			if absf(dx) <= ARRIVE_EPSILON:
				velocity = Vector2.ZERO
				global_position.x = CORNER_X[_corner]
				_start_aiming()
			else:
				velocity = Vector2(clampf(dx / delta, -travel_speed, travel_speed), 0.0)
		State.FALLING:
			velocity.y += FALL_GRAVITY * delta
			if global_position.y - radius > OFFSCREEN_Y:
				defeated.emit()
				queue_free()


func _attack(delta: float) -> void:
	if _state == State.FALLING:
		return
	_contact_timer = maxf(_contact_timer - delta, 0.0)
	if _contact_timer > 0.0:
		return
	for body in contact_hitbox.get_overlapping_bodies():
		# A standing player is never hit, only a jumping one
		if body.has_method("knock_down") and body is CharacterBody2D \
				and not (body as CharacterBody2D).is_on_floor():
			body.knock_down(contact_damage)
			_contact_timer = CONTACT_COOLDOWN
			return


func _on_died() -> void:
	# No favour and no queue_free yet: it falls off screen first
	_state = State.FALLING
	velocity = Vector2.ZERO
	modulate = Color.WHITE
	set_deferred(&"collision_layer", 0)
	contact_hitbox.set_deferred(&"monitoring", false)


# ---------- Shooting ----------

func _start_aiming() -> void:
	_state = State.AIMING
	_aim_locked = false
	_shot_timer = SHOT_WAIT_ENRAGED if _health_fraction() <= ENRAGE_FRACTION else SHOT_WAIT


func _update_aiming(delta: float) -> void:
	_shot_timer -= delta
	if _shot_timer <= 0.0:
		_shoot()
		return
	if _shot_timer > TELEGRAPH_TIME:
		return
	if not _aim_locked:
		# The shot goes where the player WAS at this moment
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null:
			_aim_dir = global_position.direction_to(player.global_position)
		_aim_locked = true
	modulate = Color.WHITE.lerp(TELEGRAPH_COLOR, 1.0 - _shot_timer / TELEGRAPH_TIME)


func _shoot() -> void:
	modulate = Color.WHITE
	if asteroid_scene != null:
		var rock: Asteroid = asteroid_scene.instantiate()
		rock.direction = _aim_dir
		if spawner != null:
			# Count is fixed at firing time, bound to the spawner so it survives the Moon.
			# Deferred: landing happens inside a physics callback, bodies can't be added there
			rock.landed.connect(spawner.spawn_walkers_at.bind(_spawn_count()), CONNECT_DEFERRED)
		get_tree().current_scene.add_child(rock)
		rock.global_position = global_position + _aim_dir * radius
	_corner = 1 - _corner
	_face_corner()
	_state = State.TRAVELLING


func _spawn_count() -> int:
	var fraction := _health_fraction()
	if fraction <= 0.5:
		return 4
	if fraction <= 0.75:
		return 3
	return 2


func _health_fraction() -> float:
	return float(health.current_health) / float(health.max_health)


# The art is lit on the left, mirrored on the left corner so the lit side shows
func _face_corner() -> void:
	visual.flip_h = _corner == 0
