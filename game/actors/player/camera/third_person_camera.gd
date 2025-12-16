extends Camera3D

@onready var target: Node3D = $"../Player"

@export var target_height: float = 1.5      # Высота точки прицеливания над центром игрока.
@export var distance: float = 15.0          # Базовая дистанция до цели.
@export var min_distance: float = 5.0       # Минимальный отъезд камеры колёсиком.
@export var max_distance: float = 30.0      # Максимальный отъезд камеры колёсиком.
@export var mouse_sensitivity: float = 0.005
@export var rotation_smooth_speed: float = 10.0
@export var position_smooth_speed: float = 10.0
@export var smoothing_enabled: bool = false
@export_flags_3d_physics var collision_mask: int = 1
@export var collision_radius: float = 0.4

var yaw: float = 0.0    # Горизонтальный угол (в радианах).
var pitch: float = -0.4 # Вертикальный угол (в радианах).

var _smoothed_position: Vector3 = Vector3.ZERO
var _smoothed_distance: float = 0.0


func _ready() -> void:
	if target:
		# Вычисляем yaw/pitch из текущего положения камеры, чтобы сохранить ориентацию.
		var dir: Vector3 = global_position - target.global_position
		distance = dir.length()

		if distance > 0.001:
			yaw = atan2(dir.x, dir.z)
			var horiz_len := Vector2(dir.x, dir.z).length()
			pitch = atan2(dir.y, horiz_len)

	_smoothed_position = global_position
	_smoothed_distance = distance

	# Стартуем с видимым курсором, правой кнопкой включается вращение.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	# Вращение камеры при зажатой ПКМ.
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var motion := event as InputEventMouseMotion
		yaw -= motion.relative.x * mouse_sensitivity
		pitch -= motion.relative.y * mouse_sensitivity

		# Ограничиваем вертикальный угол, чтобы не уехать под землю/над головой.
		pitch = clamp(pitch, deg_to_rad(-70.0), deg_to_rad(-10.0))

	# Зум колесиком.
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			distance = max(min_distance, distance - 1.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			distance = min(max_distance, distance + 1.0)


func _process(delta: float) -> void:
	if not target:
		return

	var target_pos: Vector3 = target.global_position + Vector3(0.0, target_height, 0.0)
	if smoothing_enabled:
		var dist_alpha := _smooth_factor(position_smooth_speed, delta)
		_smoothed_distance = lerp(_smoothed_distance, distance, dist_alpha)
	else:
		_smoothed_distance = distance

	var offset: Vector3 = Vector3(0.0, 0.0, _smoothed_distance)

	var cam_basis := Basis()
	cam_basis = cam_basis.rotated(Vector3.UP, yaw)
	cam_basis = cam_basis.rotated(cam_basis.x, pitch)
	offset = cam_basis * offset

	# Коллизия камеры: отрезаем луч до препятствия.
	offset = _clip_offset(target_pos, offset)

	if not smoothing_enabled:
		_smoothed_position = target_pos + offset
		global_position = _smoothed_position
		look_at(target_pos, Vector3.UP)
		return

	# Сглаживаем позицию камеры.
	var pos_alpha := _smooth_factor(position_smooth_speed, delta)
	_smoothed_position = _smoothed_position.lerp(target_pos + offset, pos_alpha)

	global_position = _smoothed_position
	look_at(target_pos, Vector3.UP)


func _clip_offset(target_pos: Vector3, desired_offset: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(target_pos, target_pos + desired_offset)
	query.collide_with_areas = false
	query.collision_mask = collision_mask
	query.exclude = [target]

	var result: Dictionary = space.intersect_ray(query)
	if result.has("position"):
		var hit_pos: Vector3 = result.position
		var dir := desired_offset.normalized()
		var clipped_dist: float = max(0.1, target_pos.distance_to(hit_pos) - collision_radius)
		return dir * clipped_dist

	return desired_offset


func _smooth_factor(speed: float, delta: float) -> float:
	# Экспоненциальное сглаживание (быстрое при больших speed).
	return 1.0 - pow(0.001, speed * delta)
