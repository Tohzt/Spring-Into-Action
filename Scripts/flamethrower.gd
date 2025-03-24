extends Node2D
@onready var Player: PlayerClass = get_parent()
@onready var anim := $AnimatedSprite2D
@onready var raycast := $RayCast2D
@onready var area_2d := $Area2D

const FUEL_CONSUMPTION_RATE := 50.0  # Fuel units per second
const DAMAGE_RATE := 0.1  # Damage per second
const DAMAGE_AMOUNT := 1  # Amount of damage per tick

var end_pos: Vector2
var base_scale := 0.45
var prev_grid_positions: Array[Vector2i] = []
var start_animation_progress: float = 0.0
var damage_timer: float = 0.0
var overlapping_enemies: Array[Node2D] = []

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
	
	# Connect only the body_exited signal since body_entered is already connected in the scene
	area_2d.body_exited.connect(_on_area_2d_body_exited)

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
			
		# Deal continuous damage to overlapping enemies
		damage_timer += delta
		if damage_timer >= DAMAGE_RATE:
			damage_timer = 0
			for enemy in overlapping_enemies:
				if is_instance_valid(enemy) and enemy.has_method("take_damage"):
					enemy.take_damage(DAMAGE_AMOUNT, true)
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
				# Force change to spring without checking snowball count
				var game := Player.get_parent()
				game.change_tile_season(grid_pos, "spring", game.layer_1, true)
				#game.change_tile_season(grid_pos, "spring", game.layer_2, true)
				game.change_tile_season(grid_pos, "spring", game.layer_plants, true)
				game.change_tile_season(grid_pos, "spring", game.layer_tree, true)

func _on_animation_finished() -> void:
	match anim.animation:
		"start":
			anim.play("hold")
		"end":
			queue_free()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body and body in overlapping_enemies:
		overlapping_enemies.erase(body)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		overlapping_enemies.append(body)

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
