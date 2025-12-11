extends CharacterBody3D

# ----- ДВИЖЕНИЕ -----
const SPEED: float = 5.0

# ----- ПАРАМЕТРЫ ВЫЖИВАНИЯ -----
var health: float = 100.0
var warmth: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0

# скорость убывания (единиц в секунду)
const WARMTH_DECAY: float       = 2.0
const HUNGER_DECAY: float       = 0.5
const THIRST_DECAY: float       = 0.8
const HEALTH_COLD_DAMAGE: float = 3.0

# таймер для редкого вывода в консоль
var _log_timer: float = 0.0


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_stats(delta)
	_log_stats(delta)


func _handle_movement(delta: float) -> void:
	# Вектор ввода: x (A/D), y (W/S)
	var input_vec: Vector2 = Vector2.ZERO
	input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")

	var direction: Vector3 = Vector3.ZERO

	if input_vec != Vector2.ZERO:
		# Берём текущую активную 3D-камеру
		var cam: Camera3D = get_viewport().get_camera_3d()

		if cam != null:
			var basis: Basis = cam.global_transform.basis

			# Вперёд камеры (в Godot вперёд — минус Z)
			var forward: Vector3 = -basis.z
			var right: Vector3   =  basis.x

			# Проецируем на плоскость XZ
			forward.y = 0.0
			right.y   = 0.0

			forward = forward.normalized()
			right   = right.normalized()

			# Итоговое направление: «вперёд/назад» + «влево/вправо» от камеры
			direction = (right * input_vec.x + forward * input_vec.y).normalized()
		else:
			# Фоллбэк: без камеры – двигаемся по осям мира
			direction = Vector3(input_vec.x, 0.0, input_vec.y).normalized()

	# Применяем скорость по XZ
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Поворачиваем тело в сторону движения (для красоты; при капсуле не критично)
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	# Пока без прыжков/гравитации
	velocity.y = 0.0

	move_and_slide()


func _update_stats(delta: float) -> void:
	# базовое убывание
	warmth -= WARMTH_DECAY * delta
	hunger -= HUNGER_DECAY * delta
	thirst -= THIRST_DECAY * delta

	warmth = clamp(warmth, 0.0, 100.0)
	hunger = clamp(hunger, 0.0, 100.0)
	thirst = clamp(thirst, 0.0, 100.0)

	# ----- УРОН ПО ЗДОРОВЬЮ -----
	var health_loss: float = 0.0

	# Замёрз — урон
	if warmth <= 0.0:
		health_loss += HEALTH_COLD_DAMAGE * delta

	# Сильный голод — урон (если голод <= 0)
	if hunger <= 0.0:
		health_loss += 2.0 * delta  # можешь потом подкрутить

	# Сильная жажда — урон (делаем сильнее, чем голод)
	if thirst <= 0.0:
		health_loss += 4.0 * delta

	health -= health_loss
	health = clamp(health, 0.0, 100.0)

	if health <= 0.0:
		_on_player_dead()


func _on_player_dead() -> void:
	print("Игрок умер. (пока просто сообщение, потом сделаем экран смерти)")


func _log_stats(delta: float) -> void:
	_log_timer += delta
	if _log_timer >= 1.0:
		_log_timer = 0.0
		print("HP: %.1f | Warmth: %.1f | Hunger: %.1f | Thirst: %.1f" % [health, warmth, hunger, thirst])
