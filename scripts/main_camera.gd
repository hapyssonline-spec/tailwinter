extends Camera3D

@onready var target: Node3D = $"../Player"

@export var target_height: float = 1.5      # на какой высоте от игрока висит взгляд
@export var distance: float       = 15.0    # текущая дистанция до игрока
@export var min_distance: float   = 5.0     # минимальный зум
@export var max_distance: float   = 30.0    # максимальный зум

@export var mouse_sensitivity: float = 0.005

var yaw: float = 0.0    # поворот вокруг вертикали (влево/вправо)
var pitch: float = -0.4 # наклон вверх/вниз (в радианах)


func _ready() -> void:
	if target:
		# Вычисляем начальные yaw/pitch и дистанцию из текущего положения камеры
		var dir: Vector3 = global_position - target.global_position
		distance = dir.length()

		if distance > 0.001:
			yaw = atan2(dir.x, dir.z)
			var horiz_len := Vector2(dir.x, dir.z).length()
			pitch = atan2(dir.y, horiz_len)

	# Мышь оставляем видимой, вращаем камеру только при зажатой ПКМ
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	# Вращение камеры при зажатой правой кнопке мыши
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var motion := event as InputEventMouseMotion
		yaw   -= motion.relative.x * mouse_sensitivity
		pitch -= motion.relative.y * mouse_sensitivity

		# Ограничиваем наклон, чтобы камера не уходила под землю/над головой
		pitch = clamp(pitch, deg_to_rad(-70.0), deg_to_rad(-10.0))

	# Зум колесиком
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			distance = max(min_distance, distance - 1.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			distance = min(max_distance, distance + 1.0)


func _process(delta: float) -> void:
	if not target:
		return

	# Точка, на которую смотрим (примерно центр игрока)
	var target_pos: Vector3 = target.global_position + Vector3(0.0, target_height, 0.0)

	# Базовый оффсет по Z (камера "за спиной" на расстоянии distance)
	var offset: Vector3 = Vector3(0.0, 0.0, distance)

	# Поворачиваем оффсет по yaw и pitch
	var basis := Basis()
	basis = basis.rotated(Vector3.UP, yaw)
	basis = basis.rotated(basis.x, pitch)
	offset = basis * offset

	global_position = target_pos + offset
	look_at(target_pos, Vector3.UP)
