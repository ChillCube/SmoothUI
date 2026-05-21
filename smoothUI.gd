## Base class for UI elements with smooth movement and relative positioning
@icon("res://addons/SmoothUI/icon_transition.png")
@tool
extends Sprite2D
class_name SmoothUI

# --- Movement Logic ---
var mover : SmoothMovement = null
var _target_position : Vector2 = Vector2.ZERO
var original_position : Vector2 = Vector2.ZERO

# --- Relative Positioning Logic ---
@export_group("Relative Positioning")
@export var use_relative_positioning : bool = false: ## Relative positioning ensures the UI stays on the same spot even when the screens are different.
	set(val):
		use_relative_positioning = val
		_update_position()

@export var anchor_point : Vector2 = Vector2(0.5, 0.5): ## The normalized screen coordinate (0.0 to 1.0) used as the element's origin.
	set(val):
		anchor_point = val
		_update_position()

@export var local_position : Vector2 = Vector2.ZERO: ## The local offset relative to the anchor point when the element is visible.
	set(val):
		local_position = val
		_update_position()

@export var off_screen_position : Vector2 = Vector2(0.0, 0.6): ## The local offset relative to the anchor point when the element is hidden.
	set(val):
		off_screen_position = val
		_update_position()

@export var is_hidden : bool = false: ## If true, the element moves to its off-screen position.
	set(val):
		is_hidden = val
		_update_target_position()

@export_group("Spawn Animation")
@export var spawn_animation : bool = true ## If true, the element scales from 0 to its original scale when it first appears.
@export var spawn_speed : float = 12.0 ## Controls how fast the scale-in animation plays.

@export_group("Despawn Animation")
@export var despawn_animation : bool = true ## If true, despawn() scales the element to 0 before freeing it.
@export var despawn_speed : float = 12.0 ## Controls how fast the scale-out animation plays.

@export_group("Movement Settings")
@export var bounce : bool = false ## Enables an elastic bounce effect when the element reaches its target position.
@export var tilt_on : bool = false;
@export_range(0.0, 10.0, 0.1) var tilt_strength : float = 1.0 ## How strongly horizontal velocity affects the tilt angle
@export_range(0.0, 3.14, 0.01) var max_tilt : float = 0.4 ## Maximum tilt angle in radians
@export var rotation_on : bool = false ## If enabled, the element will slightly tilt/rotate during movement.
@export var speed : float = 10 ## The speed multiplier for the smooth movement transition.
@export var use_smooth_movement : bool = true ## Whether to use smooth tweening or instant positioning.

var current_off_screen_pixels : Vector2
var _movement_complete: bool = false
var _spawn_tween : Tween

signal position_changed(new_position: Vector2) ## Emitted when the movement target changes
signal movement_completed ## Emitted once when the element arrives at its target position

func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	# Initialize smooth movement
	mover = SmoothMovement.init(self)
	mover.set("bounce", bounce)
	mover.set("rotation_on", rotation_on)
	mover.set("speed", speed)
	mover.tilt_on = tilt_on;
	mover.tilt_strength = tilt_strength
	mover.max_tilt = max_tilt;
	mover.scale_on = false
	
	# Connect to viewport changes
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_position)
	
	_update_position()
	_update_target_position()

	if spawn_animation:
		call_deferred("_play_spawn_animation")

	if get_parent() is NodeArranger:
		use_relative_positioning = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_position()
		return
	
	if use_smooth_movement and mover and use_relative_positioning:
		mover.set("global_target_position", _target_position)
		var dist = global_position.distance_to(_target_position)
		if dist < 2.0 and not _movement_complete:
			movement_completed.emit()
			_movement_complete = true
		elif dist >= 2.0:
			_movement_complete = false
	elif use_relative_positioning:
		global_position = _target_position

func _update_position() -> void:
	if not use_relative_positioning:
		return
	
	if get_parent() and get_parent().get_class() == "NodeArranger":
		# Don't use relative positioning if parent is NodeArranger
		return
	
	var viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return
	
	original_position = (viewport_size * anchor_point) + (viewport_size * local_position)
	current_off_screen_pixels = viewport_size * off_screen_position
	_update_target_position()

func _update_target_position() -> void:
	if is_hidden:
		_target_position = original_position + current_off_screen_pixels
	else:
		_target_position = original_position
	
	position_changed.emit(_target_position)

func set_visible_position(offset: Vector2) -> void: ## Sets the visible-position offset and refreshes the layout target
	local_position = offset
	_update_position()

func set_hidden_position(offset: Vector2) -> void: ## Sets the off-screen-position offset and refreshes the layout target
	off_screen_position = offset
	_update_position()

func teleport_to_target() -> void: ## Instantly snaps the element to its target position, bypassing smooth movement
	if use_relative_positioning:
		global_position = _target_position

func get_original_position() -> Vector2: ## Returns the current visible (on-screen) target position in global space
	return original_position

func get_target_position() -> Vector2: ## Returns the current movement target position (visible or hidden) in global space
	return _target_position

func set_movement_enabled(enabled: bool) -> void: ## Enables or disables smooth tweening; when false the element jumps instantly to its target
	use_smooth_movement = enabled

func show_ui() -> void: ## Moves the element to its visible position by clearing the hidden flag
	is_hidden = false

func hide_ui() -> void: ## Moves the element to its off-screen position by setting the hidden flag
	is_hidden = true

func despawn() -> void: ## Scales the element to zero then frees it. Call this instead of queue_free() on SmoothUI nodes.
	if not despawn_animation or Engine.is_editor_hint():
		queue_free()
		return
	if is_instance_valid(_spawn_tween):
		_spawn_tween.kill()
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 1.0 / despawn_speed)
	tween.tween_callback(queue_free)

func _play_spawn_animation() -> void:
	var target_scale := scale
	scale = Vector2.ZERO
	_spawn_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spawn_tween.tween_property(self, "scale", target_scale, 1.0 / spawn_speed)
