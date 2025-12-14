extends CanvasLayer

@onready var health_bar  = $Bars/HealthBar
@onready var warmth_bar  = $Bars/WarmthBar
@onready var hunger_bar  = $Bars/HungerBar
@onready var thirst_bar  = $Bars/ThirstBar
@onready var inventory_panel: Control = $Inventory
@onready var wind_label: Label = $Inventory/MarginContainer/VBoxContainer/WindLabel

const WIND_UPDATE_INTERVAL: float = 0.25

var _wind_source: Node = null
var _wind_update_timer: float = 0.0

func update_stats(health: float, warmth: float, hunger: float, thirst: float) -> void:
        health_bar.value = health
        warmth_bar.value = warmth
        hunger_bar.value = hunger
        thirst_bar.value = thirst


func _ready() -> void:
        _update_wind_label()


func _process(delta: float) -> void:
        if not inventory_panel.visible:
                return

        _wind_update_timer += delta
        if _wind_update_timer >= WIND_UPDATE_INTERVAL:
                _wind_update_timer = 0.0
                _update_wind_label()


func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed("inventory"):
                inventory_panel.visible = not inventory_panel.visible
                if inventory_panel.visible:
                        _update_wind_label()


func set_wind_source(wind_node: Node) -> void:
        if _wind_source != null and _wind_source.is_connected("wind_changed", Callable(self, "_on_wind_changed")):
                _wind_source.disconnect("wind_changed", Callable(self, "_on_wind_changed"))

        _wind_source = wind_node

        if _wind_source != null and _wind_source.has_signal("wind_changed"):
                _wind_source.connect("wind_changed", Callable(self, "_on_wind_changed"))

        _update_wind_label()


func _on_wind_changed(speed_mps: float, _dir: Vector3) -> void:
        _update_wind_label(speed_mps)


func _update_wind_label(speed_override: float = -1.0) -> void:
        var value_text := "—"

        var speed: float = speed_override
        if speed < 0.0 and _wind_source != null and _wind_source.has_method("get_wind_speed_mps"):
                speed = _wind_source.get_wind_speed_mps()

        if speed >= 0.0:
                value_text = "%.1f" % speed

        wind_label.text = "Ветер: %s м/с" % value_text
