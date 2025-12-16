extends Resource
class_name InventoryData

signal inventory_changed

const SLOT_COUNT: int = 20
const DEFAULT_MAX_STACK: int = 99

var slots: Array = []


func _init() -> void:
	slots.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		slots[i] = null


func add(id: String, amount: int) -> int:
	if amount <= 0:
		return 0
	var remaining: int = amount

	# Fill existing stacks
	for i in SLOT_COUNT:
		var slot_variant: Variant = slots[i]
		if slot_variant == null:
			continue
		var slot_dict: Dictionary = slot_variant
		if slot_dict.get("id", "") != id:
			continue
		var space: int = DEFAULT_MAX_STACK - int(slot_dict.get("count", 0))
		if space <= 0:
			continue
		var to_add: int = min(space, remaining)
		slot_dict["count"] = int(slot_dict.get("count", 0)) + to_add
		slots[i] = slot_dict
		remaining -= to_add
		if remaining <= 0:
			_emit_changed()
			return 0

	# Fill empty slots
	for i in SLOT_COUNT:
		if slots[i] != null:
			continue
		var to_add: int = min(DEFAULT_MAX_STACK, remaining)
		slots[i] = { "id": id, "count": to_add }
		remaining -= to_add
		if remaining <= 0:
			_emit_changed()
			return 0

	_emit_changed()
	return remaining


func add_item(id: String, weight: float = 0.0) -> bool:
	# Добавляет одну штуку с возможными метаданными (вес). Не стекается.
	for i in SLOT_COUNT:
		if slots[i] != null:
			continue
		slots[i] = {
			"id": id,
			"count": 1,
			"weight": weight,
		}
		_emit_changed()
		return true
	return false


func find_first(id: String) -> int:
	for i in SLOT_COUNT:
		var slot: Dictionary = slots[i] as Dictionary
		if slot != null and slot.get("id", "") == id:
			return i
	return -1


func remove_item_at(index: int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	slots[index] = null
	_emit_changed()


func remove(id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	var remaining: int = amount
	for i in SLOT_COUNT:
		var slot_variant: Variant = slots[i]
		if slot_variant == null:
			continue
		var slot_dict: Dictionary = slot_variant
		if slot_dict.get("id", "") != id:
			continue
		var take: int = min(int(slot_dict.get("count", 0)), remaining)
		slot_dict["count"] = int(slot_dict.get("count", 0)) - take
		slots[i] = slot_dict
		remaining -= take
		if int(slot_dict.get("count", 0)) <= 0:
			slots[i] = null
		if remaining <= 0:
			_emit_changed()
			return true
	_emit_changed()
	return remaining <= 0


func count(id: String) -> int:
	var total: int = 0
	for i in SLOT_COUNT:
		var slot_variant: Variant = slots[i]
		if slot_variant == null:
			continue
		var slot_dict: Dictionary = slot_variant
		if slot_dict.get("id", "") == id:
			total += int(slot_dict.get("count", 0))
	return total


func get_slot(index: int):
	if index < 0 or index >= SLOT_COUNT:
		return null
	return slots[index]


func set_slot(index: int, data) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	slots[index] = data
	_emit_changed()


func clear() -> void:
	for i in SLOT_COUNT:
		slots[i] = null
	_emit_changed()


func _emit_changed() -> void:
	inventory_changed.emit()
