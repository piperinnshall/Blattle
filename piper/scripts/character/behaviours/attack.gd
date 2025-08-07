extends Resource
class_name Attack

enum AttackType {
	NONE,
	LIGHT,
	HEAVY
}

@export var light_attack_scene: PackedScene
@export var heavy_attack_scene: PackedScene
@export var light_startup_frames: int = 3
@export var heavy_startup_frames: int = 10

var _queued_attack: AttackType = AttackType.NONE
var _is_attacking := false
var _frame_counter := 0

func perform(character):
	if _is_attacking:
		return

	if character._get_light_input():
		_queued_attack = AttackType.LIGHT
	elif character._get_heavy_input():
		_queued_attack = AttackType.HEAVY
	else:
		_queued_attack = AttackType.NONE
	
	if _queued_attack == AttackType.NONE:
		return

	_is_attacking = true
	_frame_counter = 0

func update(character, _delta):
	if not _is_attacking:
		return
		
	_frame_counter += 1
	
	var startup_frames = 0
	match _queued_attack:
		AttackType.LIGHT:
			startup_frames = light_startup_frames
		AttackType.HEAVY:
			startup_frames = heavy_startup_frames
		_: startup_frames = 0
	if _frame_counter == startup_frames:
		_spawn_hitbox(character, _queued_attack)
	if _frame_counter > startup_frames + 5:
		_is_attacking = false
		_queued_attack = AttackType.NONE

func _spawn_hitbox(character, attack_type: AttackType):
	var scene = null
	match attack_type:
		AttackType.LIGHT:
			scene = light_attack_scene
		AttackType.HEAVY:
			scene = heavy_attack_scene
		_:
			return
	
	if scene == null:
		return

	var hitbox = scene.instantiate()

	var dir = character._get_movement_input()
	if dir < 0:
		hitbox.position = character.position + Vector2(-16, 0)
		hitbox.scale.x = -1
	elif dir > 0:
		hitbox.position = character.position + Vector2(16, 0)
		hitbox.scale.x = 1
	else:
		hitbox.position = character.position + Vector2(0, -16)
	character.get_parent().add_child(hitbox)
