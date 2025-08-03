extends Character

func _physics_process(delta):
	_process_input()
	super._physics_process(delta)

func _process_input():
	input_dir = 0
	if Input.is_action_pressed("ui_right"):
		input_dir += 1
	if Input.is_action_pressed("ui_left"):
		input_dir -= 1
	if Input.is_action_just_pressed("ui_up"):
		buffer_jump()

# --- Override ---

func _handle_movement(_delta):
	velocity.x = input_dir * speed
