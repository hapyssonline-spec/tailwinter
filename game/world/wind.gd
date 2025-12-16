extends Node
class_name Wind

signal wind_changed(speed_mps: float, dir_xz: Vector3)

@export var max_speed: float = 32.0
@export var interval_min: float = 10.0
@export var interval_max: float = 30.0
@export var prob_speed_change: float = 0.6
@export var prob_dir_change: float = 0.35
@export var prob_gust: float = 0.1
@export var max_speed_step: float = 10.0
@export var max_speed_change_per_sec: float = 3.0
@export var dir_lerp_speed: float = 1.5
@export var gust_bonus: float = 8.0
@export var calm_bias: float = 0.4
@export var change_threshold_speed: float = 0.2
@export var change_threshold_angle_deg: float = 5.0

var _current_speed: float = 0.0
var _current_dir_xz: Vector3 = Vector3.FORWARD
var _target_speed: float = 4.0
var _target_dir_xz: Vector3 = Vector3.FORWARD
var _timer: float = 0.0
var _next_interval: float = 15.0
var _last_dir_xz: Vector3 = Vector3.FORWARD


func _ready() -> void:
	_current_dir_xz = Vector3.FORWARD
	_target_dir_xz = _current_dir_xz
	_next_interval = randf_range(interval_min, interval_max)
	_last_dir_xz = _current_dir_xz
	_emit_if_changed()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _next_interval:
		_timer = 0.0
		_next_interval = randf_range(interval_min, interval_max)
		_pick_new_targets()

	_update_current(delta)


func _pick_new_targets() -> void:
	var changed := false

	if randf() < prob_speed_change:
		var step_bias := randf_range(-max_speed_step, max_speed_step)
		step_bias += calm_bias * (1.0 - (_target_speed / max_speed))
		var new_target: float = clamp(_target_speed + step_bias, 0.0, max_speed)
		if randf() < prob_gust:
			new_target = clamp(new_target + gust_bonus, 0.0, max_speed)
		_target_speed = new_target
		changed = true

	if randf() < prob_dir_change:
		var angle: float = randf_range(-PI * 0.25, PI * 0.25)
		var basis: Basis = Basis(Vector3.UP, angle)
		_target_dir_xz = (basis * _target_dir_xz).normalized()
		changed = true

	if changed:
		_emit_if_changed()


func _update_current(delta: float) -> void:
	var max_step: float = max_speed_change_per_sec * delta
	var prev_speed: float = _current_speed
	var prev_dir: Vector3 = _current_dir_xz
	_current_speed = move_toward(_current_speed, _target_speed, max_step)

	var lerp_t: float = clamp(dir_lerp_speed * delta, 0.0, 1.0)
	_current_dir_xz = _current_dir_xz.lerp(_target_dir_xz, lerp_t).normalized()

	if _has_significant_change(prev_speed, prev_dir):
		_emit_if_changed()
	_last_dir_xz = _current_dir_xz


func _has_significant_change(prev_speed: float, prev_dir: Vector3) -> bool:
	var speed_diff: float = abs(prev_speed - _current_speed)
	if speed_diff >= change_threshold_speed:
		return true
	var angle: float = rad_to_deg(acos(clamp(prev_dir.dot(_current_dir_xz), -1.0, 1.0)))
	return angle >= change_threshold_angle_deg


func _emit_if_changed() -> void:
	wind_changed.emit(_current_speed, _current_dir_xz)


func get_wind_speed_mps() -> float:
	return _current_speed


func get_wind_dir_xz() -> Vector3:
	return _current_dir_xz


func get_wind_vector_xz() -> Vector3:
	return _current_dir_xz * _current_speed


func set_target_speed(speed: float) -> void:
	_target_speed = clamp(speed, 0.0, max_speed)


func nudge_target_speed(delta_speed: float) -> void:
	set_target_speed(_target_speed + delta_speed)
