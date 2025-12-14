extends Node3D

const WIND_MAX_SPEED: float = 75.0

@export var warmth_restore_rate := 10.0   # скорость восстановления тепла в секунду
@export var base_fuel_decay: float = 0.02  # базовая скорость затухания
@export var initial_fuel: float = 1.0
@export var fire_wind_factor_max: float = 20.0

var player_in_range: Node3D = null
var _fuel: float = 1.0
var _wind: Node = null


func _ready() -> void:
        _fuel = initial_fuel
        _wind = _find_wind_node()


func _process(delta: float) -> void:
        _update_fire_decay(delta)

        if player_in_range == null or _fuel <= 0.0:
                return

        # Пытаемся увеличить warmth у объекта, если у него есть такое свойство
        if player_in_range.has_method("_update_stats"):
                # если бы нужно было что-то особенное
                pass

        # Прямо обращаемся к переменной warmth (наш Player её имеет)
        if "warmth" in player_in_range:
                var intensity := clamp(_fuel, 0.0, 1.0)
                player_in_range.warmth = min(
                        100.0,
                        player_in_range.warmth + warmth_restore_rate * intensity * delta
                )


func _on_warm_area_body_entered(body: Node) -> void:
        if body.name == "Player":
                player_in_range = body


func _on_warm_area_body_exited(body: Node) -> void:
        if body == player_in_range:
                player_in_range = null


func _update_fire_decay(delta: float) -> void:
        if _fuel <= 0.0:
                return

        var wind_speed: float = _get_wind_speed()
        var wind_fire_factor: float = 1.0 + pow(wind_speed / WIND_MAX_SPEED, 3.0) * fire_wind_factor_max
        var decay: float = base_fuel_decay * wind_fire_factor * delta
        _fuel = max(0.0, _fuel - decay)


func _get_wind_speed() -> float:
        var wind_node := _get_wind_node()
        if wind_node != null and wind_node.has_method("get_wind_speed_mps"):
                return wind_node.get_wind_speed_mps()
        return 0.0


func _get_wind_node() -> Node:
        if _wind == null or not is_instance_valid(_wind):
                _wind = _find_wind_node()
        return _wind


func _find_wind_node() -> Node:
        var wind_nodes := get_tree().get_nodes_in_group("wind")
        if not wind_nodes.is_empty():
                return wind_nodes[0]
        if get_parent() != null and get_parent().has_node("Wind"):
                return get_parent().get_node("Wind")
        return null
