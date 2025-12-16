extends CanvasLayer

@export var player_path: NodePath

@onready var _inventory_menu: Control = $Root/InventoryMenu
@onready var _toast_label: Label = $Root/Toast
@onready var _toast_timer: Timer = $Root/ToastTimer
@onready var _hp_bar: ProgressBar = $Root/TopLeftPanel/Stats/HPRow/HPBar
@onready var _hp_value: Label = $Root/TopLeftPanel/Stats/HPRow/HPValue
@onready var _bt_bar: ProgressBar = $Root/TopLeftPanel/Stats/BodyTempRow/BodyTempBar
@onready var _bt_value: Label = $Root/TopLeftPanel/Stats/BodyTempRow/BodyTempValue
@onready var _hunger_bar: ProgressBar = $Root/TopLeftPanel/Stats/HungerRow/HungerBar
@onready var _hunger_value: Label = $Root/TopLeftPanel/Stats/HungerRow/HungerValue
@onready var _thirst_bar: ProgressBar = $Root/TopLeftPanel/Stats/ThirstRow/ThirstBar
@onready var _thirst_value: Label = $Root/TopLeftPanel/Stats/ThirstRow/ThirstValue
@onready var _stamina_bar: ProgressBar = $Root/TopLeftPanel/Stats/StaminaRow/StaminaBar
@onready var _stamina_value: Label = $Root/TopLeftPanel/Stats/StaminaRow/StaminaValue
@onready var _interact_hint: Label = $Root/InteractHint
@onready var _campfire_menu: Control = $Root/CampfireMenu

var player: Node
var _inventory: InventoryData
var _stats_timer: float = 0.0


func _ready() -> void:
	add_to_group("hud")
	_ensure_actions()
	if _campfire_menu and _campfire_menu.has_method("close_menu"):
		_campfire_menu.call("close_menu")
	_toast_timer.timeout.connect(_on_toast_timeout)
	_find_player()
	if _inventory_menu and _inventory_menu.has_method("set_inventory"):
		_inventory_menu.set_inventory(null)
	_hide_toast()


func _process(delta: float) -> void:
	_stats_timer += delta
	if _stats_timer >= 0.1:
		_stats_timer = 0.0
		_update_from_player()
	_handle_toggle_inventory()


func update_stats(stats) -> void:
	_apply_stats(stats)


func update_inventory(inv) -> void:
	if _inventory == inv:
		return
	_inventory = inv
	if _inventory_menu and _inventory_menu.has_method("set_inventory"):
		_inventory_menu.call("set_inventory", _inventory)
	if _inventory_menu and _inventory_menu.has_method("set_player"):
		_inventory_menu.call("set_player", player)


func show_toast(text: String) -> void:
	if _toast_label == null:
		return
	_toast_label.text = text
	_toast_label.visible = true
	_toast_timer.start()


func _on_toast_timeout() -> void:
	_hide_toast()


func _hide_toast() -> void:
	if _toast_label:
		_toast_label.visible = false


func _handle_toggle_inventory() -> void:
	if not Input.is_action_just_pressed("toggle_inventory"):
		return
	if _inventory_menu == null:
		return
	if _inventory_menu.visible:
		_close_inventory()
	else:
		_open_inventory()


func _open_inventory() -> void:
	if _inventory_menu.has_method("open_menu"):
		_inventory_menu.call("open_menu")
	else:
		_inventory_menu.visible = true
	if player and player.has_method("set_ui_blocked"):
		player.call("set_ui_blocked", true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_inventory() -> void:
	if _inventory_menu.has_method("close_menu"):
		_inventory_menu.call("close_menu")
	else:
		_inventory_menu.visible = false
	if player and player.has_method("set_ui_blocked"):
		player.call("set_ui_blocked", false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _update_from_player() -> void:
	if player == null or not is_instance_valid(player):
		_find_player()
		return

	if player.has_method("get_stats"):
		_apply_stats(player.call("get_stats"))
	elif "stats" in player:
		_apply_stats(player.stats)

	if "inventory" in player:
		update_inventory(player.inventory)
	if _inventory_menu and _inventory_menu.has_method("set_status_effects") and player != null and player.has_method("get_status_effects"):
		var eff: Dictionary = player.call("get_status_effects")
		_inventory_menu.call("set_status_effects", eff)


func _apply_stats(stats_data) -> void:
	var hp := 0.0
	var hp_max := 100.0
	var bt := 0.0
	var bt_max := 100.0
	var hunger := 0.0
	var thirst := 0.0
	var stamina := 0.0
	var hunger_max := 100.0
	var thirst_max := 100.0
	var stamina_max := 100.0

	if stats_data is Dictionary:
		hp = stats_data.get("hp", hp)
		hp_max = stats_data.get("hp_max", hp_max)
		bt = stats_data.get("body_temp", bt)
		bt_max = stats_data.get("body_temp_max", bt_max)
		hunger = stats_data.get("hunger", hunger)
		hunger_max = stats_data.get("hunger_max", hunger_max)
		thirst = stats_data.get("thirst", thirst)
		thirst_max = stats_data.get("thirst_max", thirst_max)
		stamina = stats_data.get("stamina", stamina)
		stamina_max = stats_data.get("stamina_max", stamina_max)
	elif stats_data != null:
		if "health" in stats_data:
			hp = stats_data.health
		if "body_temperature" in stats_data:
			bt = stats_data.body_temperature
		if "hunger" in stats_data:
			hunger = stats_data.hunger
		if "thirst" in stats_data:
			thirst = stats_data.thirst
		if "stamina" in stats_data:
			stamina = stats_data.stamina

	_set_bar(_hp_bar, _hp_value, hp, hp_max)
	_set_bar(_bt_bar, _bt_value, bt, bt_max)
	_set_bar(_hunger_bar, _hunger_value, hunger, hunger_max)
	_set_bar(_thirst_bar, _thirst_value, thirst, thirst_max)
	_set_bar(_stamina_bar, _stamina_value, stamina, stamina_max)


func _set_bar(bar: ProgressBar, label: Label, value: float, max_value: float) -> void:
	if bar == null or label == null:
		return
	bar.max_value = max_value
	bar.value = clamp(value, 0.0, max_value)
	var pct := 0
	if max_value > 0:
		pct = int(round((value / max_value) * 100.0))
	label.text = str(pct, "%")


func _find_player() -> void:
	if player_path != NodePath("") and has_node(player_path):
		player = get_node(player_path)
	if player == null:
		var list := get_tree().get_nodes_in_group("player")
		if list.size() > 0:
			player = list[0]
	if player != null and player.has_method("set_ui_blocked"):
		player.call("set_ui_blocked", false)
	if _inventory_menu and _inventory_menu.has_method("set_player"):
		_inventory_menu.call("set_player", player)


func _ensure_actions() -> void:
	if _campfire_menu and _campfire_menu.has_method("close_menu"):
		_campfire_menu.call("close_menu")
	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var ev_i := InputEventKey.new()
		ev_i.physical_keycode = KEY_I
		InputMap.action_add_event("toggle_inventory", ev_i)
		var ev_tab := InputEventKey.new()
		ev_tab.physical_keycode = KEY_TAB
		InputMap.action_add_event("toggle_inventory", ev_tab)


func set_interact_hint(text: String) -> void:
	if _interact_hint == null:
		return
	if text.strip_edges() == "":
		_interact_hint.visible = false
	else:
		_interact_hint.text = text
		_interact_hint.visible = true


func open_campfire_menu(campfire: Node) -> void:
	if _campfire_menu and _campfire_menu.has_method("open"):
		_campfire_menu.call("open", campfire, player)
	if player and player.has_method("set_ui_blocked"):
		player.call("set_ui_blocked", true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_campfire_menu() -> void:
	if _campfire_menu and _campfire_menu.has_method("close_menu"):
		_campfire_menu.call("close_menu")
	if player and player.has_method("set_ui_blocked"):
		player.call("set_ui_blocked", false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
