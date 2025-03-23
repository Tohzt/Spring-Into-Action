class_name PlayerClass extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 50.0
var DECELERATION := 0.1
const WALK_THRESHOLD := 5.0 
var current_speed := SPEED  # Add this line to track current speed
var is_in_water := false  # Add flag for water detection

const MAX_HEALTH := 100.0
var current_health := MAX_HEALTH
var is_dead := false
var damage_cooldown := 0.0
const DAMAGE_COOLDOWN_TIME := 0.5  # Time in seconds between damage instances
# Fuel related variables
const MAX_FUEL := 100.0
var current_fuel := MAX_FUEL
const FUEL_REFILL_RATE := 10.0  # Fuel units per second when not using flamethrower

var prev_grid_pos: Vector2i
var grid_pos: Vector2i

func is_in_special_region(coords: Vector2i) -> bool:
	# First 4x6 region: [4,7] to [7,12]
	if coords.x >= 4 and coords.x <= 7 and coords.y >= 7 and coords.y <= 12:
		return true
	# Second 4x6 region: [12,7] to [15,12]
	if coords.x >= 12 and coords.x <= 15 and coords.y >= 7 and coords.y <= 12:
		return true
	return false

func is_in_water_region(coords: Vector2i) -> bool:
	print("in water: ", coords)
	# Only set water flag for specific cells
	if coords == Vector2i(5,1) or coords == Vector2i(13,1):
		is_in_water = true
	
	# First water region: [4,0] to [7,5]
	if coords.x >= 4 and coords.x <= 7 and coords.y >= 0 and coords.y <= 5:
		return true
	# Second water region: [12,0] to [15,5]
	if coords.x >= 12 and coords.x <= 15 and coords.y >= 0 and coords.y <= 5:
		return true
	return false

func _process(delta: float) -> void:
	if is_dead:
		return
		
	grid_pos = floor(position/Global.grid_size)
	if grid_pos != prev_grid_pos:
		prev_grid_pos = grid_pos
		var tilemap := get_parent().get_node("TileMaps/Layer 1")
		var atlas_coords: Vector2 = tilemap.get_cell_atlas_coords(grid_pos)
		
		# Reset movement parameters
		current_speed = SPEED
		DECELERATION = 0.1
		is_in_water = false  # Reset water flag
		
		# Check for special ice regions
		if is_in_special_region(atlas_coords):
			DECELERATION = 0.01
			# No seasonal changes on ice
		# Check for water regions
		elif is_in_water_region(atlas_coords):
			current_speed = SPEED * 0.5  # Reduce speed by 50% in water
			# Apply seasonal changes on water
			var _winter: bool = Input.is_action_pressed("shift")
			var season := "winter" if _winter else "spring"
			get_parent().change_tile_season(grid_pos, season)
			get_parent().change_tile_season(grid_pos, season, get_parent().layer_plants)
		else:
			# Apply seasonal changes on normal ground
			var _winter: bool = Input.is_action_pressed("shift")
			var season := "winter" if _winter else "spring"
			get_parent().change_tile_season(grid_pos, season)
			get_parent().change_tile_season(grid_pos, season, get_parent().layer_plants)
	
	_update_direction()
	_refill_fuel(delta)
	
	# Update damage cooldown
	if damage_cooldown > 0:
		damage_cooldown -= delta

func _update_direction() -> void:
	var speed := velocity.length()
	var anim_prefix := "Walk_" if speed >= WALK_THRESHOLD else "Idle_"
	var degrees := rad_to_deg(velocity.angle())
	if degrees < 0: degrees += 360
	
	if $InputController.aiming:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var direction: Vector2 = (mouse_pos - position).normalized()
		degrees = rad_to_deg(direction.angle())
	
	var direction_index: int = int((degrees + 22.5) / 45) % 8
	var directions: Array[String] = ["R", "RD", "D", "DL", "L", "LU", "U", "UR"]
	var animation: String = anim_prefix + directions[direction_index]
	
	if animated_sprite_2d.animation != animation:
		animated_sprite_2d.animation = animation
		animated_sprite_2d.play()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
		
	var direction := Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
	velocity = direction * current_speed if direction else lerp(velocity, Vector2.ZERO, DECELERATION)
	move_and_slide()
	
	# Check for enemy collisions
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is EnemyClass:
			take_damage(10.0)

func _refill_fuel(delta: float) -> void:
	if current_fuel < MAX_FUEL:
		current_fuel = min(MAX_FUEL, current_fuel + FUEL_REFILL_RATE * delta)

func has_fuel() -> bool:
	return current_fuel > 0

func consume_fuel(amount: float) -> void:
	current_fuel = max(0, current_fuel - amount)

func take_damage(amount: float) -> void:
	if damage_cooldown <= 0:
		current_health = max(0, current_health - amount)
		damage_cooldown = DAMAGE_COOLDOWN_TIME
		
		# Visual feedback
		animated_sprite_2d.modulate = Color(1, 0.3, 0.3, 1)
		var tween := create_tween()
		tween.tween_property(animated_sprite_2d, "modulate", Color(1, 1, 1, 1), 0.3)
		
		if current_health <= 0:
			die()

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	velocity = Vector2.ZERO
	
	# Visual death effect
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)
	
	# Create a timer to change to the menu scene after 5 seconds
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(func() -> void: get_tree().change_scene_to_file(Global.MENU))
