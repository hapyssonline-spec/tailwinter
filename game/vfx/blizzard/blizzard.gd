extends GPUParticles3D

@export var follow_target_path: NodePath
@export var follow_camera_fallback: bool = true
@export var height_offset: float = 6.0
@export var wind_lerp_speed: float = 1.5
@export var min_wind_speed: float = 6.0
@export var max_wind_speed: float = 18.0
@export var base_gravity: float = -2.5
@export var base_spread: float = 14.0
@export var base_amount: int = 1400
@export var max_amount: int = 2200
@export var wind_threshold: float = 12.0
@export var wind_max_ref: float = 32.0

var _target_dir: Vector3 = Vector3(-0.6, -0.2, 0.4)
var _current_dir: Vector3 = _target_dir
var _target_speed: float = 0.0
var _current_speed: float = 0.0
var _restart_cooldown: float = 0.0

const AMOUNT_CHANGE_THRESHOLD: int = 50
const RESTART_COOLDOWN_SEC: float = 0.6


func _ready() -> void:
	if process_material:
		process_material = process_material.duplicate()
	emitting = false
	_apply_wind()


func _process(delta: float) -> void:
	_follow_target()
	if _restart_cooldown > 0.0:
		_restart_cooldown -= delta

	var t: float = clamp(wind_lerp_speed * delta, 0.0, 1.0)
	_current_dir = _current_dir.lerp(_target_dir, t)
	_current_speed = lerp(_current_speed, _target_speed, t)
	_apply_wind()


func set_active(active: bool) -> void:
	emitting = active
	if not active:
		_target_speed = 0.0


func set_wind(dir: Vector3, speed: float) -> void:
	if dir.length() < 0.001:
		dir = Vector3(0.0, -0.1, 0.0)
	_target_dir = dir.normalized()
	_target_speed = clamp(speed, 0.0, max_wind_speed)
	_adjust_amount(speed)


func _apply_wind() -> void:
	if process_material == null:
		return

	var pmat: ParticleProcessMaterial = process_material
	var dir: Vector3 = _current_dir.normalized()
	var speed: float = clamp(_current_speed, 0.0, max_wind_speed)

	pmat.direction = dir
	pmat.gravity = Vector3(0.0, base_gravity, 0.0)

	var min_v: float = max(min_wind_speed, speed * 0.8)
	var max_v: float = max(min_wind_speed + 0.5, speed * 1.1)
	pmat.initial_velocity_min = min_v
	pmat.initial_velocity_max = max_v

	# Чем сильнее ветер, тем шире конус разлёта.
	var spread: float = clamp(base_spread + speed * 0.8, base_spread, 45.0)
	pmat.angle_min = -spread
	pmat.angle_max = spread


func _adjust_amount(speed: float) -> void:
	var norm: float = clamp((speed - wind_threshold) / max(wind_max_ref, 0.01), 0.0, 1.0)
	var base_target: float = lerp(float(base_amount), float(max_amount), norm)
	var mult: float = _blizzard_amount_multiplier(speed)
	var target: int = int(round(base_target * mult))
	var clamped_target: int = clamp(target, base_amount, int(round(float(max_amount) * 5.0)))
	if abs(clamped_target - amount) >= AMOUNT_CHANGE_THRESHOLD or amount == 0:
		amount = clamped_target
		if emitting and _restart_cooldown <= 0.0:
			restart()
			_restart_cooldown = RESTART_COOLDOWN_SEC


func _follow_target() -> void:
	var target := _get_target()
	if target:
		var pos := target.global_transform.origin
		pos.y += height_offset
		global_transform.origin = pos


func _get_target() -> Node3D:
	if follow_target_path != NodePath() and has_node(follow_target_path):
		var n := get_node(follow_target_path)
		if n is Node3D:
			return n
	if follow_camera_fallback:
		return get_viewport().get_camera_3d()
	return null


func _blizzard_amount_multiplier(speed: float) -> float:
	if speed >= 32.0:
		return 5.0
	if speed >= 30.0:
		var t30: float = clamp((speed - 30.0) / 2.0, 0.0, 1.0)
		return lerp(4.0, 5.0, t30)
	if speed >= 25.0:
		var t25: float = clamp((speed - 25.0) / 5.0, 0.0, 1.0)
		return lerp(3.0, 4.0, t25)
	if speed >= 20.0:
		return 3.0
	if speed >= 12.0:
		var t12: float = clamp((speed - 12.0) / 8.0, 0.0, 1.0)
		return lerp(2.0, 3.0, t12)
	return 1.0
