extends Control

# Audio settings constants
const SFX_BUS_NAME: String = "SFX"
const MIN_VOLUME_DB: float = -40.0
const MAX_VOLUME_DB: float = 0.0
const DEFAULT_VOLUME_DB: float = -10.0

# Node references
@onready var menu_button: Button = $VBoxContainer/MenuButton
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var volume_label: Label = $VBoxContainer/VolumeLabel
@onready var volume_slider: HSlider = $VBoxContainer/VolumeSlider


# Audio bus index
var sfx_bus_index: int

func _ready():
	# Hide the death menu initially
	visible = false
	
	# Set up process mode for pause handling
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Get SFX audio bus index
	sfx_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)
	
	# Initialize volume controls
	setup_volume_controls()
	
	# Connect button signals
	connect_signals()

func setup_volume_controls():
	# Configure volume slider
	volume_slider.min_value = MIN_VOLUME_DB
	volume_slider.max_value = MAX_VOLUME_DB
	volume_slider.step = 1.0
	
	# Load saved volume or use default
	var saved_volume = get_saved_volume()
	volume_slider.value = saved_volume
	
	# Apply the loaded volume
	set_sfx_volume(saved_volume)
	update_volume_label(saved_volume)

func connect_signals():
	# Connect button signals
	menu_button.pressed.connect(_on_menu_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect volume slider signal
	volume_slider.value_changed.connect(_on_volume_changed)

func show_death_menu():
	# Show menu with fade-in effect
	visible = true
	get_tree().paused = true
	restart_button.grab_focus()
	
	# Fade in animation
	var tween = create_tween()
	modulate.a = 0.0
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func hide_death_menu():
	# Hide menu and unpause
	visible = false
	get_tree().paused = false

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://piper/scenes/menu/main_menu.tscn")

func _on_restart_pressed():
	print("Restarting game...")
	var players = get_tree().get_nodes_in_group("Players")
	for player in players:
		if player.has_method("reset_behaviour"): 
			player.reset_behaviour()
	hide_death_menu()
	get_tree().reload_current_scene()

func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()

func _on_volume_changed(value: float):
	# Update SFX volume when slider changes
	set_sfx_volume(value)
	update_volume_label(value)
	save_volume(value)

func set_sfx_volume(volume_db: float):
	# Apply volume to SFX bus
	if sfx_bus_index >= 0:
		AudioServer.set_bus_volume_db(sfx_bus_index, volume_db)

func update_volume_label(volume_db: float):
	# Update label to show volume percentage
	var volume_percent = db_to_percent(volume_db)
	volume_label.text = "SFX Volume: %d%%" % volume_percent

func db_to_percent(db: float) -> int:
	# Convert decibel value to percentage for display
	var normalized = (db - MIN_VOLUME_DB) / (MAX_VOLUME_DB - MIN_VOLUME_DB)
	return int(normalized * 100)

func save_volume(volume_db: float):
	# Save volume setting to user preferences
	var config = ConfigFile.new()
	config.set_value("audio", "sfx_volume", volume_db)
	config.save("user://audio_settings.cfg")

func get_saved_volume() -> float:
	# Load saved volume or return default
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err != OK:
		return DEFAULT_VOLUME_DB
	
	return config.get_value("audio", "sfx_volume", DEFAULT_VOLUME_DB)
