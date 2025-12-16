extends Control

@onready var grid: GridContainer = $Panel/Layout/Left/GridWrap/Grid
@onready var info: RichTextLabel = $Panel/Layout/Left/Info
@onready var use_button: Button = $Panel/Layout/Right/UseBtn
@onready var drop_button: Button = $Panel/Layout/Right/DropBtn
@onready var wind_label: Label = $Panel/Layout/Right/WindLabel
@onready var temperature_label: Label = $Panel/Layout/Right/TemperatureLabel
@onready var feels_like_label: Label = $Panel/Layout/Right/FeelsLikeLabel
@onready var poison_label: Label = $Panel/Layout/Right/PoisonLabel

signal closed

var inventory: InventoryData
var player: Node
var _selected_index: int = -1
var _slots: Array[Button] = []
var _wind_poll_timer: float = 0.0


func _ready() -> void:
	if grid:
		for i in range(grid.get_child_count()):
			var btn: Button = grid.get_child(i) as Button
			if btn != null:
				_slots.append(btn)
				btn.pressed.connect(Callable(self, "_on_slot_pressed").bind(i))
	if use_button:
		use_button.pressed.connect(_on_use_pressed)
	if drop_button:
		drop_button.disabled = true
	_refresh_slots()


func _process(delta: float) -> void:
	if not visible:
		return
	_wind_poll_timer += delta
	if _wind_poll_timer >= 0.25:
		_wind_poll_timer = 0.0
		_update_wind_label()
		_update_temperature_labels()
		_update_status_effects()


func set_inventory(inv: InventoryData) -> void:
	if inventory == inv:
		return
	if inventory:
		inventory.inventory_changed.disconnect(_on_inventory_changed)
	inventory = inv
	if inventory:
		inventory.inventory_changed.connect(_on_inventory_changed)
	_refresh_slots()


func set_player(p: Node) -> void:
	player = p


func open_menu() -> void:
	visible = true
	_refresh_slots()
	_select_slot(-1)


func close_menu() -> void:
	visible = false
	closed.emit()
	_wind_poll_timer = 0.0


func _on_slot_pressed(index: int) -> void:
	_select_slot(index)


func _on_use_pressed() -> void:
	_handle_use()


func _on_drop_pressed() -> void:
	pass


func _select_slot(index: int) -> void:
	_selected_index = index
	var slot_variant: Variant = _get_slot_data(index)
	if not (slot_variant is Dictionary):
		info.text = "[center][color=#ccd5e0]Пусто[/color][/center]"
	else:
		var slot: Dictionary = slot_variant
		var title := str(slot.get("id", ""))
		var count := int(slot.get("count", 0))
		var weight := float(slot.get("weight", 0.0))
		var weight_line := ""
		if weight > 0.0:
			weight_line = "\nВес: %.2f кг" % weight
		info.text = "[b]%s[/b]\nКоличество: %d%s" % [title, count, weight_line]
	_update_buttons()


func _update_buttons() -> void:
	var slot_variant: Variant = _get_slot_data(_selected_index)
	var has_item: bool = (slot_variant is Dictionary)
	if use_button:
		use_button.disabled = not has_item
	if drop_button:
		drop_button.disabled = true


func _on_inventory_changed() -> void:
	_refresh_slots()


func _refresh_slots() -> void:
	if _slots.is_empty():
		return
	for i in range(_slots.size()):
		var btn: Button = _slots[i]
		btn.text = "-"
		btn.disabled = true
		var slot_variant: Variant = _get_slot_data(i)
		if slot_variant is Dictionary:
			var slot: Dictionary = slot_variant
			var title := str(slot.get("id", ""))
			var count := int(slot.get("count", 0))
			var weight := float(slot.get("weight", 0.0))
			var suffix := ""
			if weight > 0.0:
				suffix = "\n%.2f кг" % weight
			btn.text = "%s\nx%d%s" % [title, count, suffix]
			btn.disabled = false
	_update_buttons()


func _get_slot_data(index: int) -> Variant:
	if inventory == null:
		return null
	return inventory.get_slot(index)


func _update_wind_label() -> void:
	if wind_label == null:
		return
	var wind_node: Node = _get_wind_node()
	if wind_node == null:
		wind_label.text = "Ветер: —"
		return

	var speed: float = 0.0
	if wind_node.has_method("get_wind_speed_mps"):
		speed = float(wind_node.call("get_wind_speed_mps"))
	wind_label.text = "Ветер: %.1f м/с" % speed


func _update_temperature_labels() -> void:
	if temperature_label == null or feels_like_label == null:
		return
	var world_node: Node = _get_world_node()
	if world_node == null:
		temperature_label.text = "Температура: —"
		feels_like_label.text = "Ощущается как: —"
		return
	var temp: float = 0.0
	if world_node.has_method("get_air_temperature_c"):
		temp = float(world_node.call("get_air_temperature_c"))
	var feels: float = temp
	if world_node.has_method("get_feels_like_temperature_c"):
		feels = float(world_node.call("get_feels_like_temperature_c"))
	temperature_label.text = "Температура: %.1f°C" % temp
	feels_like_label.text = "Ощущается как: %.1f°C" % feels


func _update_status_effects() -> void:
	if poison_label == null:
		return
	if player == null:
		poison_label.text = "Отравление: нет"
		return
	if player.has_method("get_status_effects"):
		var eff: Dictionary = player.call("get_status_effects")
		var active: bool = bool(eff.get("food_poisoning", false))
		if not active:
			poison_label.text = "Отравление: нет"
		else:
			var left := float(eff.get("food_poisoning_left", 0.0))
			poison_label.text = "Отравление: да (осталось ~%.0f HP)" % left


func _handle_use() -> void:
	if player == null:
		return
	var slot: Variant = _get_slot_data(_selected_index)
	if slot == null or not (slot is Dictionary):
		return
	var id: String = str(slot.get("id", ""))
	if id == "rabbit_carcass" and player.has_method("butcher_carcass"):
		player.call("butcher_carcass", _selected_index)
	elif id == "rabbit_meat_raw" and player.has_method("eat_meat"):
		player.call("eat_meat", _selected_index, false)
	elif id == "rabbit_meat_cooked" and player.has_method("eat_meat"):
		player.call("eat_meat", _selected_index, true)


func _get_wind_node() -> Node:
	var list: Array = get_tree().get_nodes_in_group("wind")
	if list.is_empty():
		return null
	return list[0]


func _get_world_node() -> Node:
	var list: Array = get_tree().get_nodes_in_group("world")
	if list.is_empty():
		return null
	return list[0]
