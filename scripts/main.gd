extends Node3D

# Солнце и окружение
@onready var sun: DirectionalLight3D      = $Sun
@onready var world_env: WorldEnvironment = $WorldEnvironment

# Игрок и HUD
@onready var player: Node3D = $Player
@onready var hud            = $HUD

func _ready() -> void:
        if player.has_signal("active_campfire_changed"):
                player.connect("active_campfire_changed", Callable(hud, "set_active_campfire"))

# Параметры цикла день/ночь
@export var day_length: float = 120.0  # длительность "суток" в секундах
var time_of_day: float = 0.25          # 0..1 (0 - рассвет, 0.5 - день, ~0.75 - ночь)

func _process(delta: float) -> void:
        # Обновляем день/ночь
        _update_day_night(delta)

	# Обновляем HUD статами игрока
	hud.update_stats(
		player.health,
		player.warmth,
		player.hunger,
		player.thirst
	)


func _update_day_night(delta: float) -> void:
	# двигаем время вперёд (циклично 0..1)
	time_of_day = fposmod(time_of_day + delta / day_length, 1.0)

	# угол солнца по X: от -30° до 210° за полный цикл
	var angle: float = lerp(-30.0, 210.0, time_of_day)
	sun.rotation_degrees.x = angle

	# насколько сейчас "день" (0 — ночь, 1 — полдень)
	var daylight: float = clamp(sin(time_of_day * TAU) * 0.5 + 0.5, 0.0, 1.0)

	# яркость солнца
	var min_light: float = 0.05
	var max_light: float = 1.5
	sun.light_energy = lerp(min_light, max_light, daylight)

	# ambient + туман
	var env: Environment = world_env.environment
	if env != null:
		env.ambient_light_energy = lerp(0.1, 0.6, daylight)   # общий свет
		env.fog_density          = lerp(0.06, 0.02, daylight) # ночью гуще, днём слабее
