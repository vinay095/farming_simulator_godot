extends Control

## Minecraft-style always-visible hotbar for tool and seed selection.
## Tapping a tool icon sets player.current_tool directly.
## When Seed tool is selected, a seed sub-bar appears.

const TOOL_TEXTURES = {
	Enum.Tool.AXE: preload("res://graphics/icons/axe.png"),
	Enum.Tool.HOE: preload("res://graphics/icons/hoe.png"),
	Enum.Tool.SWORD: preload("res://graphics/icons/sword.png"),
	Enum.Tool.WATER: preload("res://graphics/icons/water.png"),
	Enum.Tool.FISH: preload("res://graphics/icons/fish.png"),
	Enum.Tool.SEED: preload("res://graphics/icons/wheat.png"),
}

const SEED_TEXTURES = {
	Enum.Seed.TOMATO: preload("res://graphics/icons/tomato.png"),
	Enum.Seed.CORN: preload("res://graphics/icons/corn.png"),
	Enum.Seed.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Seed.WHEAT: preload("res://graphics/icons/wheat.png"),
}

var player: CharacterBody2D

@onready var tool_container: HBoxContainer = $ToolBar/ToolContainer
@onready var seed_bar: PanelContainer = $SeedBar
@onready var seed_container: HBoxContainer = $SeedBar/SeedContainer

# Cached styleboxes - created once, reused every frame
var _style_tool_selected: StyleBoxFlat
var _style_tool_normal: StyleBoxFlat
var _style_seed_selected: StyleBoxFlat
var _style_seed_normal: StyleBoxFlat

# Track last selection to skip redundant updates
var _last_tool: int = -1
var _last_seed: int = -1


func _ready() -> void:
	_create_styleboxes()
	_build_tool_buttons()
	_build_seed_buttons()
	seed_bar.hide()


func _create_styleboxes() -> void:
	_style_tool_selected = StyleBoxFlat.new()
	_style_tool_selected.bg_color = Color(1, 1, 1, 0.35)
	_style_tool_selected.border_color = Color(1, 1, 0.6, 0.8)
	_style_tool_selected.set_border_width_all(2)
	_style_tool_selected.set_corner_radius_all(4)

	_style_tool_normal = StyleBoxFlat.new()
	_style_tool_normal.bg_color = Color(0, 0, 0, 0.25)
	_style_tool_normal.set_corner_radius_all(4)

	_style_seed_selected = StyleBoxFlat.new()
	_style_seed_selected.bg_color = Color(0.6, 1, 0.6, 0.35)
	_style_seed_selected.border_color = Color(0.4, 1, 0.4, 0.8)
	_style_seed_selected.set_border_width_all(2)
	_style_seed_selected.set_corner_radius_all(4)

	_style_seed_normal = StyleBoxFlat.new()
	_style_seed_normal.bg_color = Color(0, 0, 0, 0.25)
	_style_seed_normal.set_corner_radius_all(4)


func setup(p: CharacterBody2D) -> void:
	player = p


func _build_tool_buttons() -> void:
	for tool_id in TOOL_TEXTURES:
		var btn = TextureButton.new()
		btn.texture_normal = TOOL_TEXTURES[tool_id]
		btn.custom_minimum_size = Vector2(40, 40)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.ignore_texture_size = true
		btn.name = "Tool_%d" % tool_id
		btn.pressed.connect(_on_tool_pressed.bind(tool_id))
		# Wrap in a PanelContainer for highlight
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(48, 48)
		panel.name = "ToolPanel_%d" % tool_id
		panel.add_child(btn)
		tool_container.add_child(panel)


func _build_seed_buttons() -> void:
	for seed_id in SEED_TEXTURES:
		var btn = TextureButton.new()
		btn.texture_normal = SEED_TEXTURES[seed_id]
		btn.custom_minimum_size = Vector2(36, 36)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.ignore_texture_size = true
		btn.name = "Seed_%d" % seed_id
		btn.pressed.connect(_on_seed_pressed.bind(seed_id))
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(40, 40)
		panel.name = "SeedPanel_%d" % seed_id
		panel.add_child(btn)
		seed_container.add_child(panel)


func _on_tool_pressed(tool_id: Enum.Tool) -> void:
	if not player:
		return
	player.current_tool = tool_id
	# Show seed sub-bar when seed tool selected
	seed_bar.visible = (tool_id == Enum.Tool.SEED)
	_update_highlights()


func _on_seed_pressed(seed_id: Enum.Seed) -> void:
	if not player:
		return
	player.current_seed = seed_id
	_update_highlights()


func _process(_delta: float) -> void:
	if not player:
		return
	# Only update when selection actually changed
	if player.current_tool != _last_tool or player.current_seed != _last_seed:
		_update_highlights()


func _update_highlights() -> void:
	if not player:
		return
	_last_tool = player.current_tool
	_last_seed = player.current_seed
	# Highlight selected tool
	for i in tool_container.get_child_count():
		var panel = tool_container.get_child(i)
		if i == player.current_tool:
			panel.add_theme_stylebox_override("panel", _style_tool_selected)
		else:
			panel.add_theme_stylebox_override("panel", _style_tool_normal)
	
	# Highlight selected seed
	if seed_bar.visible:
		for i in seed_container.get_child_count():
			var panel = seed_container.get_child(i)
			if i == player.current_seed:
				panel.add_theme_stylebox_override("panel", _style_seed_selected)
			else:
				panel.add_theme_stylebox_override("panel", _style_seed_normal)
