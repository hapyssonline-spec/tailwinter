extends Resource
class_name SurvivalStats

# Базовые показатели выживания игрока.

@export var health: float = 100.0
@export var body_temperature: float = 100.0
@export var hunger: float = 100.0
@export var thirst: float = 100.0
@export var stamina: float = 100.0

@export var body_temperature_decay: float = 2.0
@export var hunger_decay: float = 0.5
@export var thirst_decay: float = 0.8
@export var health_cold_damage: float = 3.0
@export var stamina_regen_rate: float = 15.0
@export var body_temperature_rate_multiplier: float = 1.0
var wind_chill_extra: float = 0.0


func update(delta: float) -> void:
	# Базовое уменьшение показателей выживания.
	body_temperature -= body_temperature_decay * body_temperature_rate_multiplier * delta
	body_temperature -= wind_chill_extra * delta
	hunger -= hunger_decay * delta
	thirst -= thirst_decay * delta

	body_temperature = clamp(body_temperature, 0.0, 100.0)
	hunger = clamp(hunger, 0.0, 100.0)
	thirst = clamp(thirst, 0.0, 100.0)
	stamina = clamp(stamina + stamina_regen_rate * delta, 0.0, 100.0)

	var health_loss := 0.0

	# Сильный холод бьёт по здоровью.
	if body_temperature <= 0.0:
		health_loss += health_cold_damage * delta

	# Голод.
	if hunger <= 0.0:
		health_loss += 2.0 * delta

	# Жажда.
	if thirst <= 0.0:
		health_loss += 4.0 * delta

	health -= health_loss
	health = clamp(health, 0.0, 100.0)


func restore_body_temperature(amount: float) -> void:
	body_temperature = clamp(body_temperature + amount, 0.0, 100.0)


func restore_hunger(amount: float) -> void:
	hunger = clamp(hunger + amount, 0.0, 100.0)


func restore_thirst(amount: float) -> void:
	thirst = clamp(thirst + amount, 0.0, 100.0)


func drain_stamina(amount: float) -> void:
	stamina = clamp(stamina - amount, 0.0, 100.0)


func set_stamina_regen_rate(rate: float) -> void:
	stamina_regen_rate = rate


func set_body_temperature_multiplier(mult: float) -> void:
	body_temperature_rate_multiplier = max(0.0, mult)


func set_wind_chill(extra_decay: float) -> void:
	wind_chill_extra = max(0.0, extra_decay)


func is_dead() -> bool:
	return health <= 0.0
