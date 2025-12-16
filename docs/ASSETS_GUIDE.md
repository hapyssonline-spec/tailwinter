# Asset Structure

- `res://assets/3d/models/{props,characters,environment}/` — экспортируемые модели (`.glb/.gltf/.fbx`), исходники DCC можно складывать в `res://assets/3d/models/_source/`.
- `res://assets/3d/textures/` — текстуры для 3D.
- `res://assets/3d/materials/`, `res://assets/3d/animations/`, `res://assets/3d/shaders/` — материалы/ресурсы для 3D.
- `res://assets/2d/{sprites,ui,tilesets,shaders}/` — всё 2D.
- `res://assets/audio/{sfx,music,voice}/`, `res://assets/fonts/`, `res://assets/vfx/particles/`.
- Сцены: `res://game/world/levels/`, `res://game/ui/`, `res://game/props/`, `res://game/actors/`.
- Скрипты: `res://game/` (editor-инструменты остаются в `res://addons/asset_tools/`).

# Нейминг

- `snake_case`, латиница, без пробелов.
- Префиксы: `ui_` для UI, `sfx_`/`music_` для аудио, `mat_` для материалов, `fx_` для VFX, `lvl_` для уровней.

# Как добавить новый 3D-проп

1) Положи модель в `res://assets/3d/models/props/` (исходник — в `_source/`, если нужно).  
2) Текстуры — в `res://assets/3d/textures/props/`, материалы — в `res://assets/3d/materials/`.  
3) Создай обёртку-сцену в `res://game/props/` (инстанс модели + коллизия/логика).  
4) Скрипт для поведения — в `res://game/` по смыслу.  
5) Используй сцену пропа в уровнях `res://game/world/levels/`.
