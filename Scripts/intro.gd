extends Control

@onready var story_text = $StoryContainer/MarginContainer/StoryText
@onready var skip_label = $SkipLabel

var scroll_speed = 40  # Pixels per second
var start_position = 0
var end_position = 0
var is_scrolling = true
var has_finished_scrolling = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Wait one frame to ensure the text is properly laid out
	await get_tree().process_frame
	
	# Set initial position of text (below the screen)
	var viewport_height = get_viewport_rect().size.y
	story_text.position.y = viewport_height
	start_position = viewport_height
	
	# Calculate end position (text height + viewport height to ensure it scrolls completely off)
	end_position = -(story_text.get_content_height() + viewport_height/4)

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file(Global.GAME)
	
	if is_scrolling:
		# Scroll the text up
		story_text.position.y -= scroll_speed * delta
		
		# Check if we've reached the end (text has scrolled completely off screen)
		if story_text.position.y <= end_position:
			is_scrolling = false
			has_finished_scrolling = true
			# Add a small delay before transitioning
			get_tree().change_scene_to_file(Global.GAME)
