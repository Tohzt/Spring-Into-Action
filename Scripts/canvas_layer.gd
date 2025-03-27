extends CanvasLayer
@export var player: PlayerClass
@export var game: GameClass
@onready var pb_health: ProgressBar = $"PB Health"
@onready var pb_fuel: ProgressBar = $"PB Fuel"
@onready var texture_rect_1 := $Snowballs/TextureRect
@onready var texture_rect_2 := $Snowballs/TextureRect2
@onready var texture_rect_3 := $Snowballs/TextureRect3
@onready var texture_rect_4 := $Snowballs/TextureRect4
@onready var texture_rect_5 := $Snowballs/TextureRect5
@onready var texture_rect_6 := $Snowballs/TextureRect6
@onready var texture_rect_7 := $Snowballs/TextureRect7
@onready var texture_rect_8 := $Snowballs/TextureRect8
@onready var texture_rect_9 := $Snowballs/TextureRect9
@onready var texture_rect_10 := $Snowballs/TextureRect10
@onready var texture_rect_11 := $Snowballs/TextureRect11
@onready var texture_rect_12 := $Snowballs/TextureRect12
@onready var texture_rect_13 := $Snowballs/TextureRect13
@onready var texture_rect_14 := $Snowballs/TextureRect14
@onready var texture_rect_15 := $Snowballs/TextureRect15
@onready var boss_progress_bar := $"Boss ProgressBar"
@onready var season_progress_bar := $"MarginContainer/Season ProgressBar"

func _ready() -> void:
	pb_fuel.value = 100 
	pb_health.value = 100
	boss_progress_bar.hide()
	
	# Connect to boss health signal using groups
	var boss := get_tree().get_first_node_in_group("SnowBoss")
	if boss:
		boss.health_updated.connect(update_boss_health)

func _process(_delta: float) -> void:
	if game:
		season_progress_bar.value = game.spring_ratio*100
	if player:
		pb_fuel.value = (player.current_fuel / player.MAX_FUEL) * 100
		pb_health.value = (player.current_health / player.MAX_HEALTH) * 100
		
		# Update snowball indicators
		var snowball_count := player.get_snowball_count()
		texture_rect_1.modulate.a = 1.0 if snowball_count >= 1 else 0.25
		texture_rect_2.modulate.a = 1.0 if snowball_count >= 2 else 0.25
		texture_rect_3.modulate.a = 1.0 if snowball_count >= 3 else 0.25
		texture_rect_4.modulate.a = 1.0 if snowball_count >= 4 else 0.25
		texture_rect_5.modulate.a = 1.0 if snowball_count >= 5 else 0.25
		texture_rect_6.modulate.a = 1.0 if snowball_count >= 6 else 0.25
		texture_rect_7.modulate.a = 1.0 if snowball_count >= 7 else 0.25
		texture_rect_8.modulate.a = 1.0 if snowball_count >= 8 else 0.25
		texture_rect_9.modulate.a = 1.0 if snowball_count >= 9 else 0.25
		texture_rect_10.modulate.a = 1.0 if snowball_count >= 10 else 0.25
		texture_rect_11.modulate.a = 1.0 if snowball_count >= 11 else 0.25
		texture_rect_12.modulate.a = 1.0 if snowball_count >= 12 else 0.25
		texture_rect_13.modulate.a = 1.0 if snowball_count >= 13 else 0.25
		texture_rect_14.modulate.a = 1.0 if snowball_count >= 14 else 0.25
		texture_rect_15.modulate.a = 1.0 if snowball_count >= 15 else 0.25
		
		# Show/hide boss health bar based on player Y position
		boss_progress_bar.visible = player.position.y < 0

func update_boss_health(current: int, max_health: int) -> void:
	boss_progress_bar.max_value = max_health
	boss_progress_bar.value = current
