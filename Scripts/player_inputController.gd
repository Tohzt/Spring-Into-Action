extends Node

@onready var Player: PlayerClass = get_parent()

var aiming: bool

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("aim"):
		aiming = true
	if Input.is_action_just_released("aim"):
		aiming = false
	
	if Input.is_action_just_pressed("click"):
		if aiming:
			start_flamethrower()
		else:
			throw_snowball()

func start_flamethrower() -> void:
	var flamethrower := Global.FLAMETHROWER.instantiate()
	Player.add_child(flamethrower)

func throw_snowball() -> void:
	var mouse_pos: Vector2 = Player.get_global_mouse_position()
	var direction: Vector2 = (mouse_pos - Player.position).normalized()
	var snowball: ProjectileClass = Global.SNOWBALL.instantiate()
	snowball.position = Player.position
	snowball.target_dir = direction
	Player.get_parent().add_child(snowball)
