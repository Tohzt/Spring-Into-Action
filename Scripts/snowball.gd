class_name ProjectileClass extends RigidBody2D

@export var lifetime: float = 3.0
@export var damage: int = 1
@export var force_magnitude: float = 1000.0

var target_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_expired)
	apply_central_force(target_dir * force_magnitude)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_on_lifetime_expired()

func _on_lifetime_expired() -> void:
	var burst := Global.SNOWBALL_BURST.instantiate()
	burst.position = position
	burst.emitting = true
	burst.finished.connect(func() -> void: burst.queue_free())
	get_parent().add_child(burst)
	queue_free()
