extends CanvasLayer

@onready var health_bar  = $Bars/HealthBar
@onready var warmth_bar  = $Bars/WarmthBar
@onready var hunger_bar  = $Bars/HungerBar
@onready var thirst_bar  = $Bars/ThirstBar

func update_stats(health: float, warmth: float, hunger: float, thirst: float) -> void:
	health_bar.value = health
	warmth_bar.value = warmth
	hunger_bar.value = hunger
	thirst_bar.value = thirst
