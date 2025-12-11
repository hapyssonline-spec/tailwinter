extends Node3D

@export var thirst_restore_rate := 15.0  # насколько быстро восстанавливаем жажду в секунду

var player_in_range: Node3D = null

func _process(delta: float) -> void:
	if player_in_range == null:
		return

	# Мы знаем, что сюда заходит только Player (смотрим по имени),
	# поэтому спокойно обращаемся к его полю thirst
	player_in_range.thirst = min(
		100.0,
		player_in_range.thirst + thirst_restore_rate * delta
	)

func _on_drink_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body

func _on_drink_area_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
