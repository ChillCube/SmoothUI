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
@export var use_relative_positioning : bool = true: ## Relative positioning ensures the UI stays on the same spot even when the screens are different.
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

@export_group("Movement Settings")
@export var bounce : bool = false ## Enables an elastic bounce effect when the element reaches its target position.
@export var rotation_on : bool = false ## If enabled, the element will slightly tilt/rotate during movement.
@export var speed : float = 10 ## The speed multiplier for the smooth movement transition.
@export var use_smooth_movement : bool = true ## Whether to use smooth tweening or instant positioning.

var current_off_screen_pixels : Vector2

signal position_changed(new_position: Vector2)
signal movement_completed

func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	# Initialize smooth movement
	mover = SmoothMovement.init(self)
	add_child(mover)
	mover.set("bounce", bounce)
	mover.set("rotation_on", rotation_on)
	mover.set("speed", speed)
	mover.tilt_on = false;
	
	# Connect to viewport changes
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_position)
	
	_update_position()
	_update_target_position()
	
	if get_parent() is NodeArranger:
		use_relative_positioning = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_position()
		return
	
	if use_smooth_movement and mover and use_relative_positioning:
		mover.set("global_target_position", _target_position)
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

func set_visible_position(offset: Vector2) -> void:
	"""Manually set the visible position offset"""
	local_position = offset
	_update_position()

func set_hidden_position(offset: Vector2) -> void:
	"""Manually set the hidden position offset"""
	off_screen_position = offset
	_update_position()

func teleport_to_target() -> void:
	"""Instantly move to the target position without smooth movement"""
	if use_relative_positioning:
		global_position = _target_position

func get_original_position() -> Vector2:
	return original_position

func get_target_position() -> Vector2:
	return _target_position

func set_movement_enabled(enabled: bool) -> void:
	"""Enable or disable smooth movement"""
	use_smooth_movement = enabled

func show_ui() -> void:
	"""Show the UI element"""
	is_hidden = false

func hide_ui() -> void:
	"""Hide the UI element"""
	is_hidden = true
