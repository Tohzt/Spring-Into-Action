class_name EnemyClass extends RigidBody2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: ProgressBar = $ProgressBar

var hp_max: int = 10
var hp: int = hp_max
var base_scale: float = 0.4  # Original sprite scale from scene
var max_scale: float = 1.5
var min_scale: float = 1.0
var melted_threshold: float = 1.25  # Scale threshold for melted state

# AI properties
enum State {IDLE, WANDER, CHASE, MELTED}
var current_state: State = State.IDLE
var player: PlayerClass = null
var detection_range: float = 100.0
var chase_range: float = 150.0
var wander_range: float = 100.0
var base_move_speed: float = 20.0
var move_speed: float = base_move_speed
var min_move_speed: float = 7.5
var max_move_speed: float = base_move_speed
var base_dmg: int = 10
var dmg: int = base_dmg
var min_dmg: int = 2
var max_dmg: int = base_dmg
var next_wander_point: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var wander_interval: float = 3.0 # Time between wandering to new positions
var spawn_position: Vector2 # Starting position to wander around

# Animation state
var was_chasing: bool = false
var is_melted: bool = false

# For line of sight checks
var space_state: PhysicsDirectSpaceState2D

# Tile modification variables
var prev_grid_pos: Vector2i
var grid_pos: Vector2i

func _ready() -> void:
	health.max_value = hp_max
	health.hide()
	animated_sprite_2d.play("Idle")
	player = get_tree().get_first_node_in_group("Player")
	spawn_position = global_position
	_pick_random_wander_target()
	space_state = get_world_2d().direct_space_state
	# Set initial grid position
	grid_pos = Vector2i(floor(position / Global.grid_size))
	prev_grid_pos = grid_pos
	# Set initial scale
	_update_scale()
	# Make sure enemy is not affected by gravity for wandering

func _process(delta: float) -> void:
	animated_sprite_2d.flip_h = player.global_position.x > global_position.x
	_update_scale()

	if hp < hp_max:
		health.show()
	health.value = lerp(health.value, float(hp), delta*10)
	
	# Update grid position and change tiles to winter when moving
	grid_pos = Vector2i(floor(position / Global.grid_size))
	if grid_pos != prev_grid_pos:
		prev_grid_pos = grid_pos
		# Always change to winter
		get_parent().get_parent().change_tile_season(grid_pos, "winter")

func _physics_process(delta: float) -> void:
	if current_state == State.MELTED:
		return
		
	match current_state:
		State.IDLE:
			_process_idle_state(delta)
		State.WANDER:
			_process_wander_state(delta)
		State.CHASE:
			_process_chase_state(delta)
	
	# Update state based on player position and visibility
	_update_state()

func _process_idle_state(delta: float) -> void:
	wander_timer += delta
	if wander_timer >= wander_interval:
		wander_timer = 0
		current_state = State.WANDER
		_pick_random_wander_target()

func _process_wander_state(_delta: float) -> void:
	var direction := (next_wander_point - global_position).normalized()
	apply_central_force(direction * move_speed)
	
	# If we're close enough to the target point, go back to idle
	if global_position.distance_to(next_wander_point) < 10:
		current_state = State.IDLE
		linear_velocity = Vector2.ZERO

func _process_chase_state(_delta: float) -> void:
	if player and is_instance_valid(player):
		var direction := (player.global_position - global_position).normalized()
		apply_central_force(direction * move_speed*1.5)
	else:
		current_state = State.IDLE

func _update_state() -> void:
	if is_melted:
		return
		
	if player and is_instance_valid(player):
		var distance_to_player := global_position.distance_to(player.global_position)
		
		# If player is within detection range, check line of sight
		if distance_to_player <= detection_range:
			# Check line of sight
			var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position)
			query.exclude = [get_rid()] # Exclude self from collision check
			query.collision_mask = 1  # Layer 1 is the Tilemap's collision layer
			var result := space_state.intersect_ray(query)
			
			# Debug line to visualize the ray cast
			if OS.is_debug_build():
				queue_redraw()
			
			# Only chase if we didn't hit anything (clear line of sight) or we hit the player
			if result:
				if result.collider == player:
					if not was_chasing:
						was_chasing = true
						animated_sprite_2d.play("Angry")
						await animated_sprite_2d.animation_finished
						animated_sprite_2d.play("Idle")
					current_state = State.CHASE
				elif current_state == State.CHASE:
					# Lost line of sight, so go back to wandering
					current_state = State.WANDER
					_pick_random_wander_target()
					was_chasing = false
					animated_sprite_2d.play("Idle")
			else:
				# No obstacles between enemy and player
				if not was_chasing:
					was_chasing = true
					animated_sprite_2d.play("Angry")
					await animated_sprite_2d.animation_finished
					animated_sprite_2d.play("Idle")
				current_state = State.CHASE
		
		# If chasing but player goes out of chase range, go back to wandering
		elif current_state == State.CHASE:
			current_state = State.WANDER
			_pick_random_wander_target()
			was_chasing = false
			animated_sprite_2d.play("Idle")
	
	# If we were chasing but lost the player
	elif current_state == State.CHASE:
		current_state = State.WANDER
		_pick_random_wander_target()
		was_chasing = false
		animated_sprite_2d.play("Idle")

func _pick_random_wander_target() -> void:
	var random_angle := randf_range(0, 2 * PI)
	var random_distance := randf_range(0, wander_range)
	next_wander_point = spawn_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	wander_timer = 0

func take_damage(_dmg: int, from_flamethrower: bool = false) -> void:
	hp -= _dmg
	if from_flamethrower and not is_melted:
		var current_scale := animated_sprite_2d.scale.x / base_scale
		if current_scale <= melted_threshold:
			is_melted = true
			current_state = State.MELTED
			animated_sprite_2d.play("Melted")
			linear_velocity = Vector2.ZERO  # Stop movement when melted
	if hp <= 0:
		melt()

func melt() -> void:
	queue_free()

func _update_scale() -> void:
	var health_percent := float(hp) / float(hp_max)
	var scale_factor: float = lerp(min_scale, max_scale, health_percent)
	
	# Scale the sprite (considering the base scale)
	animated_sprite_2d.scale = Vector2(base_scale, base_scale) * scale_factor
	
	# Scale the collision shape
	collision_shape_2d.scale = Vector2.ONE * scale_factor
	
	# Adjust health bar position based on scale
	health.position.y = -20 * scale_factor
	
	# Scale damage and move speed based on health
	dmg = int(lerp(min_dmg, max_dmg, health_percent))
	move_speed = lerp(max_move_speed, min_move_speed, health_percent)
