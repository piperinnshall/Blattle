extends Control
class_name DeathMenu

# Audio settings constants
const SFX_BUS_NAME: String = "SFX"
const MIN_VOLUME_DB: float = -40.0
const MAX_VOLUME_DB: float = 0.0
const DEFAULT_VOLUME_DB: float = -10.0

# Node references
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var volume_label: Label = $VBoxContainer/VolumeLabel
@onready var volume_slider: HSlider = $VBoxContainer/VolumeSlider
@onready var mute_button: Button = $VBoxContainer/MuteButton

# Audio bus index
var sfx_bus_index: int

# Mute state
var is_muted: bool = false

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	sfx_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)
	setup_volume_controls()
	connect_signals()

func setup_volume_controls():
	volume_slider.min_value = MIN_VOLUME_DB
	volume_slider.max_value = MAX_VOLUME_DB
	volume_slider.step = 1.0
	
	var saved_volume = get_saved_volume()
	volume_slider.value = saved_volume
	set_sfx_volume(saved_volume)
	update_volume_label(saved_volume)
	
	# Check current mute state and set button text accordingly
	is_muted = AudioServer.is_bus_mute(sfx_bus_index)
	mute_button.text = "Unmute" if is_muted else "Mute"

func connect_signals():
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	mute_button.pressed.connect(_on_mute_pressed)

func _on_mute_pressed():
	is_muted = !is_muted
	
	if is_muted:
		AudioServer.set_bus_mute(sfx_bus_index, true)
		mute_button.text = "Unmute"
	else:
		AudioServer.set_bus_mute(sfx_bus_index, false)
		mute_button.text = "Mute"

func show_death_menu():
	visible = true
	get_tree().paused = true
	restart_button.grab_focus()
	
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

func _on_volume_changed(value: float):
	set_sfx_volume(value)
	update_volume_label(value)
	save_volume(value)

func set_sfx_volume(volume_db: float):
	if sfx_bus_index >= 0:
		AudioServer.set_bus_volume_db(sfx_bus_index, volume_db)

func update_volume_label(volume_db: float):
	var volume_percent = db_to_percent(volume_db)
	volume_label.text = "SFX Volume: %d%%" % volume_percent

func db_to_percent(db: float) -> int:
	var normalized = (db - MIN_VOLUME_DB) / (MAX_VOLUME_DB - MIN_VOLUME_DB)
	return int(normalized * 100)

func save_volume(volume_db: float):
	var config = ConfigFile.new()
	config.set_value("audio", "sfx_volume", volume_db)
	config.save("user://audio_settings.cfg")

func get_saved_volume() -> float:
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err != OK:
		return DEFAULT_VOLUME_DB
	
	return config.get_value("audio", "sfx_volume", DEFAULT_VOLUME_DB)
