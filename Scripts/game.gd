extends Node2D
@onready var layer_1: TileMapLayer = $"TileMaps/Layer 1"
@onready var layer_2: TileMapLayer = $"TileMaps/Layer 2"
@onready var layer_plants: TileMapLayer = $"TileMaps/Layer Plants"
@onready var layer_tree: TileMapLayer = $"TileMaps/Layer Tree"
@onready var player: PlayerClass = $Player
@onready var camera: Camera2D = $Camera2D

var zoom_level := 2.0
var zoom_min := 1.0
var zoom_max := 3.0
var zoom_factor := 0.1
var camera_speed := 1.0

func _ready() -> void:
	change_all_tiles_to_season("winter")
	camera.zoom = Vector2(zoom_level, zoom_level)

func _process(delta: float) -> void:
	if !player: return
	camera.position = lerp(camera.position, player.position, delta * camera_speed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = clampf(zoom_level - zoom_factor, zoom_min, zoom_max)
			camera.zoom = Vector2(zoom_level, zoom_level)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = clampf(zoom_level + zoom_factor, zoom_min, zoom_max)
			camera.zoom = Vector2(zoom_level, zoom_level)

func change_tile_season(pos: Vector2i, season: String, layer: TileMapLayer = layer_1) -> void:
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
		"spring":
			atlas_coords.y -= vertical_shift
	
	layer.set_cell(pos, source_id, atlas_coords, alternative_tile)

func change_all_tiles_to_season(season: String) -> void:
	# Change tiles in layer 1
	var layer1_cells: Array[Vector2i] = layer_1.get_used_cells()
	for cell_pos: Vector2i in layer1_cells:
		change_tile_season(cell_pos, season, layer_1)
	
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
