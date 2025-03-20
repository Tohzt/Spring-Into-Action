class_name EnemyClass extends RigidBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var hp_max: int = 10
var hp: int = hp_max

# AI properties
enum State {IDLE, WANDER, CHASE}
var current_state: State = State.IDLE
var player: PlayerClass = null
var detection_range: float = 150.0
var chase_range: float = 200.0
var wander_range: float = 100.0
var move_speed: float = 20.0
var next_wander_point: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var wander_interval: float = 3.0 # Time between wandering to new positions
var spawn_position: Vector2 # Starting position to wander around

# For line of sight checks
var space_state: PhysicsDirectSpaceState2D

# Tile modification variables
var prev_grid_pos: Vector2i
var grid_pos: Vector2i

func _ready() -> void:
	animated_sprite_2d.play()
	player = get_tree().get_first_node_in_group("Player")
	spawn_position = global_position
	_pick_random_wander_target()
	space_state = get_world_2d().direct_space_state
	# Set initial grid position
	grid_pos = Vector2i(floor(position / Global.grid_size))
	prev_grid_pos = grid_pos
	# Make sure enemy is not affected by gravity for wandering

func _process(_delta: float) -> void:
	# Update grid position and change tiles to winter when moving
	grid_pos = Vector2i(floor(position / Global.grid_size))
	if grid_pos != prev_grid_pos:
		prev_grid_pos = grid_pos
		# Always change to winter
		get_parent().get_parent().change_tile_season(grid_pos, "winter")

func _physics_process(delta: float) -> void:
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
	#linear_velocity = direction * move_speed
	
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
					current_state = State.CHASE
				elif current_state == State.CHASE:
					# Lost line of sight, so go back to wandering
					current_state = State.WANDER
					_pick_random_wander_target()
			else:
				# No obstacles between enemy and player
				current_state = State.CHASE
		
		# If chasing but player goes out of chase range, go back to wandering
		elif current_state == State.CHASE:
			current_state = State.WANDER
			_pick_random_wander_target()
	
	# If we were chasing but lost the player
	elif current_state == State.CHASE:
		current_state = State.WANDER
		_pick_random_wander_target()

func _pick_random_wander_target() -> void:
	var random_angle := randf_range(0, 2 * PI)
	var random_distance := randf_range(0, wander_range)
	next_wander_point = spawn_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	wander_timer = 0

func take_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		melt()

func melt() -> void:
	queue_free()
