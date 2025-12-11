extends Node3D

@export var warmth_restore_rate := 10.0   # скорость восстановления тепла в секунду

var player_in_range: Node3D = null

func _process(delta: float) -> void:
	if player_in_range == null:
		return

	# Пытаемся увеличить warmth у объекта, если у него есть такое свойство
	if player_in_range.has_method("_update_stats"):
		# если бы нужно было что-то особенное
		pass

	# Прямо обращаемся к переменной warmth (наш Player её имеет)
	if "warmth" in player_in_range:
		player_in_range.warmth = min(
			100.0,
			player_in_range.warmth + warmth_restore_rate * delta
		)


func _on_warm_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body


func _on_warm_area_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
