extends CanvasLayer
@onready var pb_health: ProgressBar = $"PB Health"
@onready var pb_fuel: ProgressBar = $"PB Fuel"
@export var player: PlayerClass

func _ready() -> void:
	pb_fuel.value = 100 
	pb_health.value = 100


func _process(_delta: float) -> void:
	if player:
		pb_fuel.value = (player.current_fuel / player.MAX_FUEL) * 100
		pb_health.value = (player.current_health / player.MAX_HEALTH) * 100
