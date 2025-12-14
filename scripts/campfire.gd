extends Node3D

@export var warmth_restore_rate := 10.0   # скорость восстановления тепла в секунду

var player_in_range: Node3D = null

func _process(delta: float) -> void:
	if player_in_range == null:
		return

	# Игрок уже отфильтрован в событиях Area3D, поэтому можно напрямую работать с полем warmth
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
