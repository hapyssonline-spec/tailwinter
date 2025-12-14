extends Node

## Global debug state singleton that tracks whether debug HUD is enabled.
var enabled: bool = false

signal toggled(enabled: bool)

func toggle() -> void:
        set_enabled(!enabled)

func set_enabled(v: bool) -> void:
        if enabled == v:
                return
        enabled = v
        toggled.emit(enabled)
