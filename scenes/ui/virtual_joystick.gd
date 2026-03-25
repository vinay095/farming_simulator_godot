extends Control

## Virtual joystick that injects InputEventAction for left/right/up/down
## so the existing Input.get_vector() in player.gd works unchanged.

@export var max_drag_distance: float = 50.0
@export var deadzone: float = 0.15

@onready var knob: TextureRect = $Knob
@onready var base: TextureRect = $Base

var _touch_index: int = -1
var _center: Vector2
var _current_output: Vector2 = Vector2.ZERO

# Track which actions are currently pressed so we can release them
var _pressed_actions: Dictionary = {}


func _ready() -> void:
	_center = base.size / 2.0
	knob.position = _center - knob.size / 2.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_knob(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_reset_knob()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)


func _update_knob(touch_pos: Vector2) -> void:
	var delta = touch_pos - _center
	var dist = delta.length()
	if dist > max_drag_distance:
		delta = delta.normalized() * max_drag_distance
	knob.position = _center + delta - knob.size / 2.0
	
	var output = delta / max_drag_distance
	if output.length() < deadzone:
		output = Vector2.ZERO
	_current_output = output
	_emit_actions()


func _reset_knob() -> void:
	knob.position = _center - knob.size / 2.0
	_current_output = Vector2.ZERO
	_emit_actions()


func _emit_actions() -> void:
	var actions = {
		"left": max(0.0, -_current_output.x),
		"right": max(0.0, _current_output.x),
		"up": max(0.0, -_current_output.y),
		"down": max(0.0, _current_output.y),
	}
	for action_name in actions:
		var strength = actions[action_name]
		if strength > 0.0:
			_press_action(action_name, strength)
		else:
			_release_action(action_name)


func _press_action(action_name: String, strength: float) -> void:
	var ev = InputEventAction.new()
	ev.action = action_name
	ev.pressed = true
	ev.strength = strength
	Input.parse_input_event(ev)
	_pressed_actions[action_name] = true


func _release_action(action_name: String) -> void:
	if _pressed_actions.get(action_name, false):
		var ev = InputEventAction.new()
		ev.action = action_name
		ev.pressed = false
		ev.strength = 0.0
		Input.parse_input_event(ev)
		_pressed_actions[action_name] = false
