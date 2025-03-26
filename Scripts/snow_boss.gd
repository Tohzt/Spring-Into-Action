extends RigidBody2D
signal health_updated(current: int, max_health: int)

@onready var area: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var initial_position: Vector2 = position

# For tile modification
var prev_grid_pos: Vector2i
var grid_pos: Vector2i

var player: PlayerClass
var hp_max: int = 200
var hp: int = hp_max
var move_speed: float = 15.0
var damage: int = 20

# Spawn parameters
var spawn_radius: float = 100.0
var min_spawn_distance: float = 50.0
var max_enemies: int = 15
var spawn_interval: float = 5.0
var spawn_timer: float = 0.0

# Damage parameters
var damage_interval: float = 1.0  # How often to deal damage
var damage_timer: float = 0.0

func _ready() -> void:
	sprite.play("Idle")
	player = get_tree().get_first_node_in_group("Player")
	health_updated.emit(hp, hp_max)
	# Make sure the boss isn't affected by gravity
	gravity_scale = 0.0
	# Prevent rotation
	lock_rotation = true
	# Connect to area's body_entered signal
	area.body_entered.connect(_on_area_body_entered)
	# Set initial grid position
	grid_pos = Vector2i(floor(position / Global.grid_size))
	prev_grid_pos = grid_pos

func _process(delta: float) -> void:
	sprite.flip_h = player.global_position.x > global_position.x
	
	# Handle damage timer and check for player overlap
	damage_timer += delta
	if damage_timer >= damage_interval:
		damage_timer = 0
		var overlapping_bodies := area.get_overlapping_bodies()
		for body: Node2D in overlapping_bodies:
			if body.is_in_group("Player"):
				body.take_damage(damage)
	
	# Change all overlapping tiles to winter
	var shape := area.get_child(0) as CollisionShape2D
	var transform2d := area.global_transform
	var extents := shape.shape.get_rect().size / 2  # Half size for center-based calculations
	
	# Calculate the grid positions that the area overlaps
	var top_left := Vector2i(floor((transform2d.origin.x - extents.x) / Global.grid_size), 
						   floor((transform2d.origin.y - extents.y) / Global.grid_size))
	var bottom_right := Vector2i(ceil((transform2d.origin.x + extents.x) / Global.grid_size), 
							   ceil((transform2d.origin.y + extents.y) / Global.grid_size))
	
	# Change all tiles in the rectangular area to winter
	for x: int in range(top_left.x, bottom_right.x + 1):
		for y: int in range(top_left.y, bottom_right.y + 1):
			var tile_pos := Vector2i(x, y)
			get_parent().get_parent().change_tile_season(tile_pos, "winter")
	
	# Handle movement based on player Y position
	if player.position.y < -50:
		# Follow player when in boss area
		var direction := (player.global_position - global_position).normalized()
		apply_central_force(direction * move_speed)
		
		# Spawn enemies when in boss area
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0
			_spawn_enemy()
	else:
		# Return to initial position when player leaves boss area
		var direction := (initial_position - global_position).normalized()
		apply_central_force(direction * move_speed)

func _spawn_enemy() -> void:
	var current_enemies := get_tree().get_nodes_in_group("Enemy").size()
	if current_enemies >= max_enemies: return
	
	var random_angle := randf_range(0, 2 * PI)
	var random_distance := randf_range(min_spawn_distance, spawn_radius)
	var spawn_position := global_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	
	var enemy := Global.ENEMY.instantiate()
	enemy.global_position = spawn_position
	get_parent().add_child(enemy)

func _on_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.take_damage(damage)

func take_damage(_dmg: int, _from_flamethrower: bool = false) -> void:
	hp -= _dmg
	health_updated.emit(hp, hp_max)
	if hp <= 0:
		melt()

func melt() -> void:
	Global.win = true
	get_tree().change_scene_to_file(Global.WINLOSE)
	queue_free()
