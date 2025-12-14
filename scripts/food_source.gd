extends Node3D

@export var hunger_restore_rate := 12.0  # скорость восстановления сытости в секунду

var player_in_range: Node3D = null

func _process(delta: float) -> void:
	if player_in_range == null:
		return

	# В событиях Area3D пускаем только игрока, поэтому поле hunger точно существует
	player_in_range.hunger = min(
		100.0,
		player_in_range.hunger + hunger_restore_rate * delta
	)

func _on_eat_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body

func _on_eat_area_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
