extends Node2D
@onready var Player: PlayerClass = get_parent()
@onready var anim := $AnimatedSprite2D
@onready var raycast := $RayCast2D
@onready var area_2d := $Area2D

const FUEL_CONSUMPTION_RATE := 50.0  # Fuel units per second

var end_pos: Vector2
var base_scale := 0.45
var prev_grid_positions: Array[Vector2i] = []
var start_animation_progress: float = 0.0

func _ready() -> void:
	anim.play("start")
	anim.animation_finished.connect(_on_animation_finished)
	
	# Force the raycast to update immediately
	raycast.force_raycast_update()
	
	# Initialize scale based on collision
	if raycast.is_colliding():
		var collision_point: Vector2 = raycast.get_collision_point()
		var distance_to_collision: float = global_position.distance_to(collision_point)
		var scale_ratio: float = distance_to_collision / raycast.target_position.length()
		scale_ratio = clampf(scale_ratio, 0.1, 1.0)
		area_2d.scale.x = scale_ratio
		anim.scale.x = base_scale * scale_ratio
	else:
		# Start with a smaller area if no collision
		area_2d.scale.x = 0.5
		
	# Set collision mask for initial state
	area_2d.set_collision_mask_value(3, true)

func _process(delta: float) -> void:
	var mouse_pos: Vector2 = Player.get_global_mouse_position()
	var direction: Vector2 = (mouse_pos - Player.position).normalized()
	
	# Consume fuel while active
	if anim.animation != "end" and anim.animation != "start":
		Player.consume_fuel(FUEL_CONSUMPTION_RATE * delta)
	
	# Check if player has fuel
	if !Player.has_fuel():
		if anim.animation != "end":
			end_pos = global_position
			anim.play("end")
			area_2d.set_collision_mask_value(3, false)
		return
	
	if anim.animation != "end":
		rotation = direction.angle()
		
		# Force raycast update to ensure accurate collision detection
		raycast.force_raycast_update()
		
		# Scale up during start animation
		if anim.animation == "start":
			var frame_progress: float = float(anim.frame) / 6.0  # 7 frames (0-6)
			var base_scale_factor: float = lerp(0.5, 1.0, frame_progress)
			
			# Apply collision-based scaling if colliding
			if raycast.is_colliding():
				var collision_point: Vector2 = raycast.get_collision_point()
				var distance_to_collision: float = global_position.distance_to(collision_point)
				var collision_scale_ratio: float = distance_to_collision / raycast.target_position.length()
				collision_scale_ratio = clampf(collision_scale_ratio, 0.1, 1.0)
				
				# Use the smaller of the two scales
				area_2d.scale.x = min(base_scale_factor, collision_scale_ratio)
				anim.scale.x = base_scale * min(1.0, collision_scale_ratio)
			else:
				area_2d.scale.x = base_scale_factor
				anim.scale.x = base_scale
		else:
			_update_flame_length()
	else:
		global_position = end_pos
	
	_update_overlapping_tiles()
	
	if direction.x < 0:
		anim.flip_v = true
		anim.offset = Vector2(95.0,20.0)
	else:
		anim.flip_v = false
		anim.offset = Vector2(95.0,-20.0)
	
	if !Input.is_action_pressed("click"):
		if anim.animation != "end":
			end_pos = global_position
			anim.play("end")
			area_2d.set_collision_mask_value(3, false)

func _update_overlapping_tiles() -> void:
	var collision_shape: CollisionShape2D = area_2d.get_node("CollisionShape2D")
	var shape: CapsuleShape2D = collision_shape.shape
	
	var start_pos: Vector2 = area_2d.global_position
	var length: float = shape.height * area_2d.scale.x
	var width: float = shape.radius * 2 * area_2d.scale.y
	
	var angle := rotation
	var direction := Vector2(cos(angle), sin(angle))
	
	var num_points := 5
	for i in range(num_points):
		var t := float(i) / float(num_points - 1)
		var point: Vector2 = start_pos + direction * length * t
		
		var radius: float = width / 2.0
		for offset: float in [-radius, 0, radius]:
			var perpendicular: Vector2 = Vector2(-direction.y, direction.x) * offset
			var sample_point: Vector2 = point + perpendicular
			var grid_pos := Vector2i(floor(sample_point/Global.grid_size))
			
			if not grid_pos in prev_grid_positions:
				prev_grid_positions.append(grid_pos)
				Player.get_parent().change_tile_season(grid_pos, "spring", Player.get_parent().layer_1)
				Player.get_parent().change_tile_season(grid_pos, "spring", Player.get_parent().layer_2)
				Player.get_parent().change_tile_season(grid_pos, "spring", Player.get_parent().layer_tree)

func _on_animation_finished() -> void:
	match anim.animation:
		"start":
			anim.play("hold")
		"end":
			queue_free()

func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("Enemy"):
		body.melt()

# New function to handle flame length calculations
func _update_flame_length() -> void:
	if raycast.is_colliding():
		var collision_point: Vector2 = raycast.get_collision_point()
		var distance_to_collision: float = global_position.distance_to(collision_point)
		var scale_ratio: float = distance_to_collision / raycast.target_position.length()
		scale_ratio = clampf(scale_ratio, 0.1, 1.0)
		anim.scale.x = base_scale * scale_ratio
		area_2d.scale.x = scale_ratio 
		area_2d.scale.y = 1.0
	else:
		anim.scale.x = base_scale
		area_2d.scale = Vector2.ONE
