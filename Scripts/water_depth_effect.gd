extends Node

@export var wade_depth: int = 4

# Reference to the sprite node
var sprite: Node2D

# Original y offset of the sprite
var original_offset: float = 0

func _ready():
	# Find the sprite node (parent should be the player)
	sprite = get_parent().get_node("AnimatedSprite2D")
	if sprite:
		original_offset = sprite.position.y

# Call this when player enters water
func enter_water():
	if sprite:
		# Move the sprite down
		sprite.position.y = original_offset + wade_depth

# Call this when player exits water
func exit_water():
	if sprite:
		# Reset the sprite position
		sprite.position.y = original_offset 