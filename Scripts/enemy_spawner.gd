extends Node2D
@onready var area: Area2D = $Area2D
@onready var health: ProgressBar = $ProgressBar

@export var spawn_radius: float = 50.0
@export var min_spawn_distance: float = 10.0
@export var max_enemies: int = 25
@export var spawn_interval: float = 10.0

var player: PlayerClass
var timer: float = 0.0
var hp_max: int = 100
var hp: int = hp_max

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	health.hide()

func _process(delta: float) -> void:
	var current_enemies := get_tree().get_nodes_in_group("Enemy").size()
	if current_enemies >= max_enemies: return
	
	timer += delta
	if timer >= spawn_interval:
		timer = 0
		_spawn_enemy()
	
	if hp <= 0:
		_melt()
	else:
		# Flip based on player position
		scale.x = -1 if player.global_position.x > global_position.x else 1

		if hp < hp_max:
			health.show()
		health.value = lerp(health.value, float(hp), delta*10)

func _physics_process(_delta: float) -> void:
	var collisions := area.get_overlapping_areas()
	for collision in collisions:
		hp -= 1

func _spawn_enemy() -> void:
	var random_angle := randf_range(0, 2 * PI)
	var random_distance := randf_range(min_spawn_distance, spawn_radius)
	var spawn_position := position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	
	var enemy := Global.ENEMY.instantiate()
	enemy.global_position = spawn_position
	get_parent().add_child(enemy) 

func _melt() -> void:
	queue_free()
	
