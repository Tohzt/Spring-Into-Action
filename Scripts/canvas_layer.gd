extends CanvasLayer
@onready var pb_health: ProgressBar = $"PB Health"
@onready var pb_fuel: ProgressBar = $"PB Fuel"
@export var player: PlayerClass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize progress bars
	pb_fuel.min_value = 0
	pb_fuel.max_value = 100
	pb_fuel.value = 100  # Start with full fuel
	pb_fuel.show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player:
		pb_fuel.value = (player.current_fuel / player.MAX_FUEL) * 100
