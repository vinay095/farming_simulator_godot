extends Node

## Handles all touch/click events on the game world.
## Quick tap  → interact with entities (tree, NPC, blob, bed, TV)
## Tap & hold → use ground tools (hoe, water, seed)
## Each gesture fires exactly ONE action – no continuous firing.
##
## Handles BOTH InputEventScreenTouch (native on phones) and
## InputEventMouseButton (desktop / editor with emulate_touch_from_mouse).

var player: CharacterBody2D
var camera: Camera2D

# Gesture timing (seconds)
const TAP_MAX_TIME := 0.25       # touches shorter than this = quick tap
const HOLD_MIN_TIME := 0.25      # touch must last at least this long …
const HOLD_MAX_TIME := 0.6       # … but no longer than this to count as hold
const INTERACTION_RANGE := 40.0  # pixels — how close the player must be

# Touch tracking
var _active: bool = false        # true while a press gesture is tracked
var _start_time: float = 0.0
var _start_screen_pos: Vector2 = Vector2.ZERO
var _source_type: int = 0        # 0 = touch, 1 = mouse  — prevent double-fire


func setup(p: CharacterBody2D, cam: Camera2D) -> void:
	player = p
	camera = cam


func _unhandled_input(event: InputEvent) -> void:
	if not player or not camera:
		return

	# ── Fishing state: any tap / click = action ──
	if player.current_state == Enum.State.FISHING:
		if _is_press(event):
			_fire_action_press()
			get_viewport().set_input_as_handled()
		return

	# ── Shop state: let UI buttons handle their own input ──
	if player.current_state == Enum.State.SHOP:
		return

	# ── Building state: any tap / click = place ──
	if player.current_state == Enum.State.BUILDING:
		if _is_press(event):
			_fire_action_press()
			get_viewport().set_input_as_handled()
		return

	# ── Default state: gesture detection ──
	# --- PRESS ---
	if _is_press(event) and not _active:
		_active = true
		_start_time = Time.get_ticks_msec() / 1000.0
		_start_screen_pos = _get_event_position(event)
		_source_type = 0 if event is InputEventScreenTouch else 1
		get_viewport().set_input_as_handled()
		return

	# --- RELEASE ---
	if _is_release(event) and _active:
		# Only accept release from the same source type that started the gesture
		var release_type = 0 if event is InputEventScreenTouch else 1
		if release_type != _source_type:
			return

		var duration = Time.get_ticks_msec() / 1000.0 - _start_time
		_active = false

		var world_pos = _screen_to_world(_start_screen_pos)

		if duration < TAP_MAX_TIME:
			# ── QUICK TAP — interact with entity ──
			_handle_quick_tap(world_pos)
		elif duration >= HOLD_MIN_TIME and duration <= HOLD_MAX_TIME:
			# ── TAP & HOLD — ground tool action ──
			_handle_hold_action(world_pos)
		get_viewport().set_input_as_handled()


# ── Helpers to unify touch and mouse events ──

func _is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch and event.pressed:
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		return true
	return false


func _is_release(event: InputEvent) -> bool:
	if event is InputEventScreenTouch and not event.pressed:
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		return true
	return false


func _get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	if event is InputEventMouseButton:
		return event.position
	return Vector2.ZERO


func _handle_quick_tap(world_pos: Vector2) -> void:
	if not player.can_move or player.current_state != Enum.State.DEFAULT:
		return

	# Query physics at the tap position
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.collision_mask = 0xFFFFFFFF
	var results = space_state.intersect_point(query, 10)

	for result in results:
		var collider = result["collider"]
		var dist = player.position.distance_to(collider.position)

		# NPC / merchant — talk & open shop
		if collider.is_in_group("Characters") and dist < INTERACTION_RANGE:
			if collider.has_method("interact"):
				_face_toward(collider.position)
				collider.interact(player)
				return

		# Bed / TV — interact
		if collider is StaticBody2D and collider.has_method("interact") and not collider.is_in_group("Objects"):
			if dist < INTERACTION_RANGE:
				_face_toward(collider.position)
				collider.interact(player)
				return

		# Tree — chop (player must have correct tool selected via hotbar)
		if collider.is_in_group("Objects") and collider.has_method("hit"):
			if dist < INTERACTION_RANGE:
				if collider is StaticBody2D and "chopped" in collider:
					_face_toward(collider.position)
					player.touch_action(collider.position, player.current_tool)
					return

		# Blob — attack (player must have correct tool selected via hotbar)
		if collider is CharacterBody2D and collider.has_method("hit") and not collider.is_in_group("Player"):
			if dist < INTERACTION_RANGE * 1.5:
				_face_toward(collider.position)
				player.touch_action(collider.position, player.current_tool)
				return


func _handle_hold_action(world_pos: Vector2) -> void:
	## Tap-and-hold on the ground → use current tool (hoe / water / seed)
	if not player.can_move or player.current_state != Enum.State.DEFAULT:
		return

	var dist_to_touch = player.position.distance_to(world_pos)
	if dist_to_touch < INTERACTION_RANGE * 1.5:
		_face_toward(world_pos)
		player.touch_action(world_pos, player.current_tool)


func _face_toward(target_pos: Vector2) -> void:
	var dir = (target_pos - player.position).normalized()
	player.last_direction = dir
	var ray_y = int(dir.y) if not dir.x else 0
	player.get_node("RayCast2D").target_position = Vector2(dir.x, ray_y).normalized() * 20


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var viewport = get_viewport()
	var canvas_transform = viewport.get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_pos


func _fire_action_press() -> void:
	var ev = InputEventAction.new()
	ev.action = "action"
	ev.pressed = true
	Input.parse_input_event(ev)
	# Release after a short delay
	await get_tree().create_timer(0.1).timeout
	var ev_release = InputEventAction.new()
	ev_release.action = "action"
	ev_release.pressed = false
	Input.parse_input_event(ev_release)
