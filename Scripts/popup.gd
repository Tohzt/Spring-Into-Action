extends Control
@onready var heading: Label = $CenterContainer/VBoxContainer/Heading
@onready var volume_slider: HSlider = $"CenterContainer/VBoxContainer/Volume Slider"
@onready var back_to_game = $"CenterContainer/VBoxContainer/Back to Game"

var audio_player: AudioStreamPlayer
var is_game_scene: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	# Determine if we're in the game scene
	var parent_name = get_parent().name
	is_game_scene = parent_name == "CanvasLayer"
	
	# Set heading text based on scene
	if is_game_scene:
		heading.text = "PAUSED"
		# In game scene, the audio player is in the Game node
		# Navigate up from CanvasLayer -> Camera2D -> Game
		audio_player = get_parent().get_parent().get_parent().get_node("AudioStreamPlayer")
	else:
		back_to_game.hide()
		heading.text = "SETTINGS"
		# In menu scene, the audio player is in the parent
		audio_player = get_parent().get_node("AudioStreamPlayer")
	
	# Set initial volume
	volume_slider.value = Global.volume
	_update_volume(Global.volume)


func _on_popup_button_pressed():
	if is_game_scene:
		get_tree().change_scene_to_file(Global.MENU)
	else:
		hide()


func _on_volume_slider_drag_ended(value_changed):
	Global.volume = volume_slider.value
	_update_volume(Global.volume)


func _update_volume(value: float) -> void:
	# Convert linear slider value (0-100) to dB (-80 to 0)
	var db = linear_to_db(value / 100.0)
	audio_player.volume_db = db

func _on_back_to_game_pressed():
	hide()
