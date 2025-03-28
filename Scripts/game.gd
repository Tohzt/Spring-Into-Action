class_name GameClass extends Node2D
signal season_progress_updated(spring_ratio: float)

@onready var layer_1: TileMapLayer = $"TileMaps/Layer 1"
@onready var layer_1_5: TileMapLayer = $"TileMaps/Layer 1_5"
@onready var layer_2: TileMapLayer = $"TileMaps/Layer 2"
@onready var layer_plants: TileMapLayer = $"TileMaps/Layer Plants"
@onready var layer_tree: TileMapLayer = $"TileMaps/Layer Tree"
@onready var player: PlayerClass = $Player
@onready var camera: Camera2D = $Camera2D
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

var game_music: AudioStream = preload("res://Assets/game.mp3")
var boss_music: AudioStream = preload("res://Assets/intro and boss.mp3")

var zoom_level := 3.0
var zoom_min := 1.75
var zoom_max := 4.0
var zoom_factor := 0.1
var camera_speed := 1.0

var spring_ratio: float
var tiles_spring: int
var tiles_winter: int

func _ready() -> void:
	# Add to Game group for UI updates
	add_to_group("Game")
	
	# Initialize counters - all tiles start as spring
	tiles_spring = 2342  # Total number of tiles in layer_1
	tiles_winter = 0
	
	# Now change all tiles to winter
	change_all_tiles_to_season("winter")
	camera.zoom = Vector2(zoom_level, zoom_level)
	
	# Start with game music
	audio.stream = game_music
	audio.play()

func _process(delta: float) -> void:
	if !player: return
	camera.position = lerp(camera.position, player.position, delta * camera_speed)
	if Input.is_action_just_pressed("ui_cancel"):
		$Camera2D/CanvasLayer/Popup.show()
	# Handle music switching based on player position
	if player.position.y < -50:
		if audio.stream != boss_music:
			audio.stream = boss_music
			audio.play()
	else:
		if audio.stream != game_music:
			audio.stream = game_music
			audio.play()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = clampf(zoom_level - zoom_factor, zoom_min, zoom_max)
			camera.zoom = Vector2(zoom_level, zoom_level)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = clampf(zoom_level + zoom_factor, zoom_min, zoom_max)
			camera.zoom = Vector2(zoom_level, zoom_level)

func change_tile_season(pos: Vector2i, season: String, layer: TileMapLayer = layer_1, force: bool = false) -> void:
	var source_id: int = layer.get_cell_source_id(pos)
	var atlas_coords: Vector2i = layer.get_cell_atlas_coords(pos)
	var alternative_tile: int = layer.get_cell_alternative_tile(pos)
	
	if source_id == -1: return
	
	# Determine the vertical shift based on the layer
	var vertical_shift: int
	if layer == layer_tree:
		vertical_shift = 10
	elif layer == layer_plants:
		vertical_shift = 2
	else:
		vertical_shift = 7
		
	var current_season := "spring" if atlas_coords.y < vertical_shift else "winter"
	if current_season == season: return
	
	match season:
		"winter":
			atlas_coords.y += vertical_shift
			# Update counters for layer_1
			if layer == layer_1:
				if current_season == "spring":
					tiles_spring -= 1
					tiles_winter += 1
					update_season_progress()
		"spring":
			# Only check snowball capacity if not forcing the change
			if current_season == "winter" and !force and !player.can_collect_snowball():
				return
			atlas_coords.y -= vertical_shift
			# Update counters for layer_1
			if layer == layer_1:
				if current_season == "winter":
					tiles_winter -= 1
					tiles_spring += 1
					update_season_progress()
			# Add a snowball when changing from winter to spring, but only if not forcing
			if current_season == "winter" and !force:
				player.add_snowball()
	
	layer.set_cell(pos, source_id, atlas_coords, alternative_tile)

func update_season_progress() -> void:
	var total_tiles := tiles_spring + tiles_winter
	if total_tiles > 0:
		spring_ratio = float(tiles_spring) / total_tiles
		season_progress_updated.emit(spring_ratio)

func change_all_tiles_to_season(season: String) -> void:
	# Change tiles in layer 1
	var layer1_cells: Array[Vector2i] = layer_1.get_used_cells()
	for cell_pos: Vector2i in layer1_cells:
		change_tile_season(cell_pos, season, layer_1)
		
	# Change tiles in layer 1.5
	var layer1_5_cells: Array[Vector2i] = layer_1_5.get_used_cells()
	for cell_pos: Vector2i in layer1_5_cells:
		change_tile_season(cell_pos, season, layer_1_5)
	
	# Change tiles in layer 2
	var layer2_cells: Array[Vector2i] = layer_2.get_used_cells()
	for cell_pos: Vector2i in layer2_cells:
		change_tile_season(cell_pos, season, layer_2)
	
	# Change tiles in plants layer
	var plants_cells: Array[Vector2i] = layer_plants.get_used_cells()
	for cell_pos: Vector2i in plants_cells:
		change_tile_season(cell_pos, season, layer_plants)
	
	# Change tiles in tree layer
	var tree_cells: Array[Vector2i] = layer_tree.get_used_cells()
	for cell_pos: Vector2i in tree_cells:
		change_tile_season(cell_pos, season, layer_tree)
