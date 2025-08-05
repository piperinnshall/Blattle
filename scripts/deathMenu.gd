extends Control
class_name DeathMenu

@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready():
	# Hide the death menu initially
	visible = false
	
	# Connect button signals
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Pause the game when death menu appears
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func show_death_menu():
	visible = true
	get_tree().paused = true
	restart_button.grab_focus()  # Focus on restart button for keyboard/controller
	# In show_death_menu()
	var tween = create_tween()
	modulate.a = 0.0
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func hide_death_menu():
	visible = false
	get_tree().paused = false

func _on_restart_pressed():
	print("Restarting game...")
	hide_death_menu()
	get_tree().reload_current_scene()

func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()
