extends CanvasLayer

@onready var health_bar  = $Bars/HealthBar
@onready var warmth_bar  = $Bars/WarmthBar
@onready var hunger_bar  = $Bars/HungerBar
@onready var thirst_bar  = $Bars/ThirstBar
@onready var debug_panel = $DebugPanel
@onready var campfire_bar = $DebugPanel/FuelBar
@onready var campfire_value = $DebugPanel/FuelValue

var active_campfire: Node = null

func _ready() -> void:
        DebugState.toggled.connect(_on_debug_toggled)
        _update_debug_visibility()

func update_stats(health: float, warmth: float, hunger: float, thirst: float) -> void:
        health_bar.value = health
        warmth_bar.value = warmth
        hunger_bar.value = hunger
        thirst_bar.value = thirst


func set_active_campfire(campfire: Node) -> void:
        if active_campfire and active_campfire.is_connected("fuel_changed", Callable(self, "_on_campfire_fuel_changed")):
                active_campfire.disconnect("fuel_changed", Callable(self, "_on_campfire_fuel_changed"))

        active_campfire = campfire

        if active_campfire and active_campfire.has_signal("fuel_changed"):
                active_campfire.connect("fuel_changed", Callable(self, "_on_campfire_fuel_changed"))
                _on_campfire_fuel_changed(active_campfire.fuel, active_campfire.fuel_max)
        else:
                _clear_campfire_ui()

        _update_debug_visibility()


func _on_campfire_fuel_changed(current: float, max: float) -> void:
        campfire_bar.max_value = max
        campfire_bar.value = current
        campfire_value.text = "%.0f / %.0f" % [current, max]
        _update_debug_visibility()


func _clear_campfire_ui() -> void:
        campfire_bar.value = 0.0
        campfire_bar.max_value = 100.0
        campfire_value.text = "Нет костра"


func _on_debug_toggled(enabled: bool) -> void:
        _update_debug_visibility()


func _update_debug_visibility() -> void:
        var has_campfire := active_campfire != null
        debug_panel.visible = DebugState.enabled and has_campfire
