extends Control

signal resume_requested

@onready var settings_box: VBoxContainer = $Panel/Layout/SettingsBox
@onready var limit_blizzard_check: CheckBox = $Panel/Layout/SettingsBox/LimitBlizzard
@onready var sleep_fauna_check: CheckBox = $Panel/Layout/SettingsBox/SleepFauna
@onready var vsync_check: CheckBox = $Panel/Layout/SettingsBox/Vsync
@onready var fps_option: OptionButton = $Panel/Layout/SettingsBox/FpsLimit
@onready var fullscreen_check: CheckBox = $Panel/Layout/SettingsBox/Fullscreen
@onready var resolution_option: OptionButton = $Panel/Layout/SettingsBox/Resolution

var _resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]
var _fps_limits: Array = [0, 30, 60, 90, 120]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_setup_options()
	_connect_handlers()
	_connect_buttons()


func _setup_options() -> void:
	if fps_option:
		fps_option.clear()
		for v in _fps_limits:
			var label := "Без лимита" if v == 0 else str(v, " FPS")
			fps_option.add_item(label)
		fps_option.select(2) # 60 по умолчанию

	if resolution_option:
		resolution_option.clear()
		for res in _resolutions:
			resolution_option.add_item("%dx%d" % [res.x, res.y])
		resolution_option.select(2) # 1920x1080 по умолчанию


func _connect_handlers() -> void:
	if limit_blizzard_check:
		limit_blizzard_check.toggled.connect(_on_settings_changed)
	if sleep_fauna_check:
		sleep_fauna_check.toggled.connect(_on_settings_changed)
	if vsync_check:
		vsync_check.toggled.connect(_on_settings_changed)
	if fps_option:
		fps_option.item_selected.connect(_on_settings_changed)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_settings_changed)
	if resolution_option:
		resolution_option.item_selected.connect(_on_settings_changed)


func _connect_buttons() -> void:
	if has_node("Panel/Layout/Buttons/ResumeBtn"):
		$Panel/Layout/Buttons/ResumeBtn.pressed.connect(_on_resume_pressed)
	if has_node("Panel/Layout/ActionButtons/SaveBtn"):
		$Panel/Layout/ActionButtons/SaveBtn.pressed.connect(_on_stub_pressed.bind("Сохранить пока не реализовано"))
	if has_node("Panel/Layout/ActionButtons/LoadBtn"):
		$Panel/Layout/ActionButtons/LoadBtn.pressed.connect(_on_stub_pressed.bind("Загрузка пока не реализована"))
	if has_node("Panel/Layout/ActionButtons/ExitBtn"):
		$Panel/Layout/ActionButtons/ExitBtn.pressed.connect(_on_stub_pressed.bind("Выход пока не реализован"))


func open_menu() -> void:
	visible = true
	_update_from_current_display()


func close_menu() -> void:
	visible = false


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_settings_changed(_arg: Variant = null) -> void:
	var settings := _collect_settings()
	get_tree().call_group("world", "apply_performance_settings", settings)
	get_tree().call_group("world", "apply_display_settings", settings)


func _collect_settings() -> Dictionary:
	var fps_index := fps_option.get_selected_id() if fps_option else 0
	var fps_value: int = 0
	if fps_index >= 0 and fps_index < _fps_limits.size():
		fps_value = int(_fps_limits[fps_index])
	var res_index := resolution_option.get_selected_id() if resolution_option else 0
	var res := _resolutions[res_index] if res_index >= 0 and res_index < _resolutions.size() else DisplayServer.window_get_size()
	return {
		"limit_blizzard_emitters": limit_blizzard_check.button_pressed if limit_blizzard_check else false,
		"sleep_distant_fauna": sleep_fauna_check.button_pressed if sleep_fauna_check else false,
		"vsync": vsync_check.button_pressed if vsync_check else false,
		"fps_limit": fps_value,
		"fullscreen": fullscreen_check.button_pressed if fullscreen_check else false,
		"resolution": res,
	}


func _update_from_current_display() -> void:
	if vsync_check:
		var mode := DisplayServer.window_get_vsync_mode()
		vsync_check.button_pressed = (mode != DisplayServer.VSYNC_DISABLED)

	if fullscreen_check:
		fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	if fps_option:
		var current := Engine.max_fps
		var idx := _fps_limits.find(current)
		if idx == -1:
			idx = 0
		fps_option.select(idx)

	if resolution_option:
		var size := DisplayServer.window_get_size()
		var idx_res := _resolutions.find(size)
		if idx_res == -1:
			idx_res = 0
		resolution_option.select(idx_res)


func _on_stub_pressed(message: String) -> void:
	get_tree().call_group("hud", "show_toast", message)
