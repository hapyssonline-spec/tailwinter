extends Control

@onready var tabs: TabContainer = $Panel/Tabs
@onready var fuel_list: RichTextLabel = $Panel/Tabs/Fuel/FuelList
@onready var fuel_button: Button = $Panel/Tabs/Fuel/AddFuelButton
@onready var cook_list: RichTextLabel = $Panel/Tabs/Cook/CookList
@onready var cook_button: Button = $Panel/Tabs/Cook/CookButton
@onready var take_button: Button = $Panel/Tabs/Cook/TakeButton
@onready var status_label: Label = $Panel/Status

var campfire: Node = null
var player: Node = null
var inventory: InventoryData = null
var _selected_weight: float = 0.0


func open(campfire_ref: Node, player_ref: Node) -> void:
	campfire = campfire_ref
	player = player_ref
	if player and "inventory" in player:
		inventory = player.inventory
	visible = true
	set_process_input(true)
	_update_fuel()
	_update_cook()


func close_menu() -> void:
	visible = false
	set_process_input(false)
	if player and player.has_method("set_ui_blocked"):
		player.call("set_ui_blocked", false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if not visible:
		return
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("toggle_inventory") or event.is_action_pressed("interact"):
		close_menu()
		accept_event()


func _update_status() -> void:
	if status_label == null:
		return
	if campfire == null:
		status_label.text = ""
		return
	var line := ""
	if campfire.get("cooking_ready") > 0.01:
		line += "Готово мяса: %.2f кг. " % campfire.get("cooking_ready")
	if campfire.get("cooking_weight") > 0.01:
		line += "Готовится: %.2f кг (осталось %.0f с). " % [campfire.get("cooking_weight"), campfire.get("cooking_time_left")]
	status_label.text = line


func _update_fuel() -> void:
	if fuel_list == null:
		return
	var count := 0
	if inventory != null:
		count = inventory.count("stick")
	fuel_list.text = "Палки: %d" % count


func _update_cook() -> void:
	if cook_list == null:
		return
	_selected_weight = 0.0
	var raw_weight := 0.0
	if inventory != null:
		for i in range(inventory.SLOT_COUNT):
			var slot_variant: Variant = inventory.get_slot(i)
			if slot_variant is Dictionary:
				var slot: Dictionary = slot_variant
				if slot.get("id", "") == "rabbit_meat_raw":
					raw_weight += float(slot.get("weight", 0.0))
	cook_list.text = "Сырое мясо: %.2f кг" % raw_weight


func _on_AddFuelButton_pressed() -> void:
	if campfire and campfire.has_method("add_fuel_from_player"):
		campfire.call("add_fuel_from_player", player)
	_update_fuel()


func _on_CookButton_pressed() -> void:
	if campfire == null or player == null:
		return
	if inventory == null:
		return
	var slot_index := _find_first_raw_meat_slot()
	if slot_index == -1:
		return
	var slot: Dictionary = inventory.get_slot(slot_index) as Dictionary
	var raw_weight := float(slot.get("weight", 0.0))
	if raw_weight <= 0.0:
		return
	if campfire.has_method("start_cooking") and campfire.call("start_cooking", raw_weight):
		inventory.set_slot(slot_index, null)
	_update_cook()


func _on_TakeButton_pressed() -> void:
	if campfire and campfire.has_method("take_ready_meat"):
		campfire.call("take_ready_meat", player)
	_update_cook()


func _find_first_raw_meat_slot() -> int:
	if inventory == null:
		return -1
	for i in range(inventory.SLOT_COUNT):
		var slot_variant: Variant = inventory.get_slot(i)
		if slot_variant is Dictionary:
			var slot: Dictionary = slot_variant
			if slot.get("id", "") == "rabbit_meat_raw":
				return i
	return -1
