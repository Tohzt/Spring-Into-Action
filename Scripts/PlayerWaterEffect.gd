extends AnimatedSprite2D

@export var hidden_pixels: int = 4
var original_sprite_frames: SpriteFrames
var modified_sprite_frames: SpriteFrames
var is_modified := false

func _ready() -> void:
	# Store the original sprite frames
	original_sprite_frames = sprite_frames
	
	# Create modified version for water effect
	_create_modified_frames()

func _create_modified_frames() -> void:
	# Create a new SpriteFrames resource
	modified_sprite_frames = SpriteFrames.new()
	
	# Copy and modify each animation
	for anim in original_sprite_frames.get_animation_names():
		modified_sprite_frames.add_animation(anim)
		modified_sprite_frames.set_animation_loop(anim, original_sprite_frames.get_animation_loop(anim))
		modified_sprite_frames.set_animation_speed(anim, original_sprite_frames.get_animation_speed(anim))
		
		# For each frame in the animation
		for _frame: int in range(original_sprite_frames.get_frame_count(anim)):
			var texture := original_sprite_frames.get_frame_texture(anim, _frame)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			
			# Set the region to exclude bottom pixels
			var region := Rect2(0, 0, texture.get_width(), texture.get_height() - hidden_pixels)
			atlas.region = region
			
			modified_sprite_frames.add_frame(anim, atlas)

func _process(_delta: float) -> void:
	var player := get_parent() as PlayerClass
	if player:
		if player.is_in_water and not is_modified:
			# Switch to modified frames when entering water
			sprite_frames = modified_sprite_frames
			is_modified = true
			# Move the sprite down by the number of hidden pixels
			offset.y = hidden_pixels
		elif not player.is_in_water and is_modified:
			# Switch back to original frames when leaving water
			sprite_frames = original_sprite_frames
			is_modified = false
			# Reset the offset
			offset.y = 0 
