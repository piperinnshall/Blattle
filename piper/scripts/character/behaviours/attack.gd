extends Resource
class_name Attack

enum AttackType {
	NONE,
	LIGHT,
	HEAVY
}

@export var attack_offset: int = 64

@export_group("Durations")
@export var light_attack_duration: float = 0.15  # seconds for light hitbox (active)
@export var heavy_attack_duration: float = 0.35  # seconds for heavy hitbox (active)
@export var recovery_seconds: float = 1.0        # how long the attack is in recovery after hitbox expires

@export_group("Types")
@export var light_attack_scene: PackedScene
@export var heavy_attack_scene: PackedScene
@export var light_startup_frames: int = 3
@export var heavy_startup_frames: int = 10

var _queued_attack: AttackType = AttackType.NONE
var _is_attacking := false
var _frame_counter := 0
var _active_hitbox: Node2D = null

var _recovery_timer: float = 0.0

func is_busy() -> bool:
	return _is_attacking or _recovery_timer > 0.0
	
func reset():
	_queued_attack = AttackType.NONE
	_is_attacking = false
	_frame_counter = 0
	_recovery_timer = 0.0

	if _active_hitbox and _active_hitbox.is_inside_tree():
		_active_hitbox.queue_free()
	_active_hitbox = null


func perform(character):
	if is_busy():
		return

	if character.get_light_input():
		_queued_attack = AttackType.LIGHT
	elif character.get_heavy_input():
		_queued_attack = AttackType.HEAVY
	else:
		_queued_attack = AttackType.NONE

	if _queued_attack == AttackType.NONE:
		return

	_is_attacking = true
	_frame_counter = 0

func update(character, delta):
	if _recovery_timer > 0.0:
		_recovery_timer = max(_recovery_timer - delta, 0.0)
	
	if not _is_attacking:
		return
	
	_frame_counter += 1
	
	var startup_frames := 0
	match _queued_attack:
		AttackType.LIGHT:
			startup_frames = light_startup_frames
		AttackType.HEAVY:
			startup_frames = heavy_startup_frames
		_:
			startup_frames = 0
	
	if _frame_counter == startup_frames:
		_spawn_hitbox(character, _queued_attack)
	
	if _active_hitbox:
		_follow_character(character)

func _spawn_hitbox(character, attack_type: AttackType):
	if _active_hitbox:
		return
	
	var scene: PackedScene = null
	match attack_type:
		AttackType.LIGHT:
			scene = light_attack_scene
		AttackType.HEAVY:
			scene = heavy_attack_scene
		_:
			scene = null

	if scene == null:
		push_error("Attack scene not assigned!")
		return

	var hitbox = scene.instantiate()
	_active_hitbox = hitbox

	hitbox.connect("hitbox_expired", Callable(self, "_on_hitbox_expired"))

	if hitbox.has_node("LifeSpan"):
		var timer = hitbox.get_node("LifeSpan") as Timer
		var duration := 0.2
		match attack_type:
			AttackType.LIGHT:
				duration = light_attack_duration
			AttackType.HEAVY:
				duration = heavy_attack_duration
			_:
				duration = 0.2
		timer.wait_time = duration
		timer.one_shot = true
	
	var dir = character.get_movement_input()
	var offset = Vector2.ZERO
	if dir < 0:
		offset = Vector2(-attack_offset, 0)
	elif dir > 0:
		offset = Vector2(attack_offset, 0)
	else:
		offset = Vector2(0, -attack_offset)
	
	hitbox.position = character.position + offset
	hitbox.set_meta("offset", offset)
	
	character.get_parent().add_child(hitbox)

func _follow_character(character):
	if _active_hitbox and _active_hitbox.has_meta("offset"):
		var offset: Vector2 = _active_hitbox.get_meta("offset")
		_active_hitbox.position = character.position + offset

func _on_hitbox_expired():
	_active_hitbox = null
	_is_attacking = false
	_queued_attack = AttackType.NONE
	_frame_counter = 0
	
	_recovery_timer = recovery_seconds
