extends Node

signal wind_changed(speed_mps: float, dir_xz: Vector3)

const WIND_MAX_SPEED: float = 75.0

@export var interval_min: float = 10.0
@export var interval_max: float = 30.0
@export var prob_speed_change: float = 0.6
@export var prob_dir_change: float = 0.35
@export var prob_gust: float = 0.1
@export var max_speed_step: float = 10.0
@export var gust_bonus: float = 14.0
@export var max_dir_change_deg: float = 55.0
@export var max_speed_change_per_sec: float = 3.0
@export var dir_smoothing: float = 2.5
@export var calm_bias_strength: float = 0.35
@export var high_wind_calm_resistance: float = 0.45
@export var speed_change_emit_threshold: float = 0.2
@export var angle_emit_threshold_deg: float = 4.0

var _current_speed: float = 0.0
var _current_dir: Vector3 = Vector3.FORWARD
var _target_speed: float = 0.0
var _target_dir: Vector3 = Vector3.FORWARD
var _time_until_retarget: float = 0.0

var _last_emit_speed: float = -1.0
var _last_emit_dir: Vector3 = Vector3.ZERO


func _ready() -> void:
        randomize()
        add_to_group("wind")

        _current_dir = _random_dir()
        _target_dir = _current_dir

        _target_speed = _initial_speed()
        _current_speed = _target_speed

        _time_until_retarget = _next_interval()

        _emit_if_changed(force=true)


func _process(delta: float) -> void:
        _time_until_retarget -= delta
        if _time_until_retarget <= 0.0:
                _retarget_goals()
                _time_until_retarget = _next_interval()

        _approach_targets(delta)
        _emit_if_changed()


func get_wind_speed_mps() -> float:
        return _current_speed


func get_wind_dir_xz() -> Vector3:
        return _current_dir


func get_wind_vector_xz() -> Vector3:
        return _current_dir * _current_speed


func _next_interval() -> float:
        return randf_range(interval_min, interval_max)


func _random_dir() -> Vector3:
        var angle: float = randf_range(-PI, PI)
        return Vector3(cos(angle), 0.0, sin(angle)).normalized()


func _initial_speed() -> float:
        # чаще лёгкий ветер
        var calm_roll: float = pow(randf(), 2.0)
        return clamp(calm_roll * WIND_MAX_SPEED * 0.4, 0.0, WIND_MAX_SPEED)


func _retarget_goals() -> void:
        if randf() < prob_speed_change:
                _apply_new_target_speed()

        if randf() < prob_dir_change:
                _apply_new_target_direction()

        if randf() < prob_gust:
                _apply_gust()


func _apply_new_target_speed() -> void:
        var base_step: float = randf_range(-max_speed_step, max_speed_step)

        # слабый ветер встречается чаще
        var calm_pull: float = calm_bias_strength * (1.0 - (_target_speed / WIND_MAX_SPEED))
        base_step -= max_speed_step * calm_pull * randf()

        # высокая скорость не сбрасывается резко к штилю
        if base_step < 0.0:
                var calm_resistance: float = lerp(1.0, 1.0 - high_wind_calm_resistance, _target_speed / WIND_MAX_SPEED)
                base_step *= calm_resistance

        var new_target: float = clamp(
                _target_speed + base_step,
                0.0,
                WIND_MAX_SPEED
        )

        _target_speed = new_target


func _apply_new_target_direction() -> void:
        var angle_delta: float = deg_to_rad(randf_range(-max_dir_change_deg, max_dir_change_deg))
        var current_angle: float = atan2(_target_dir.z, _target_dir.x)
        var next_angle: float = current_angle + angle_delta
        _target_dir = Vector3(cos(next_angle), 0.0, sin(next_angle)).normalized()


func _apply_gust() -> void:
        var bonus: float = randf_range(max_speed_step * 0.5, gust_bonus)
        _target_speed = clamp(_target_speed + bonus, 0.0, WIND_MAX_SPEED)


func _approach_targets(delta: float) -> void:
        var max_delta: float = max_speed_change_per_sec * delta
        _current_speed = move_toward(_current_speed, _target_speed, max_delta)

        var current_2d: Vector2 = Vector2(_current_dir.x, _current_dir.z)
        var target_2d: Vector2 = Vector2(_target_dir.x, _target_dir.z)
        current_2d = current_2d.slerp(target_2d, clamp(dir_smoothing * delta, 0.0, 1.0))
        if current_2d.length() < 0.001:
                current_2d = target_2d
        _current_dir = Vector3(current_2d.x, 0.0, current_2d.y).normalized()


func _emit_if_changed(force: bool = false) -> void:
        var speed_diff: float = abs(_current_speed - _last_emit_speed)
        var angle_diff_deg: float = _dir_angle_deg(_last_emit_dir, _current_dir)
        if force or speed_diff >= speed_change_emit_threshold or angle_diff_deg >= angle_emit_threshold_deg:
                _last_emit_speed = _current_speed
                _last_emit_dir = _current_dir
                wind_changed.emit(_current_speed, _current_dir)


func _dir_angle_deg(a: Vector3, b: Vector3) -> float:
        if a == Vector3.ZERO or b == Vector3.ZERO:
                return 180.0
        var dot_val: float = clamp(a.normalized().dot(b.normalized()), -1.0, 1.0)
        return rad_to_deg(acos(dot_val))
