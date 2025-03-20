extends Node2D
@onready var layer_1: TileMapLayer = $"TileMaps/Layer 1"
@onready var layer_2: TileMapLayer = $"TileMaps/Layer 2"
@onready var player: PlayerClass = $Player
@onready var camera: Camera2D = $Camera2D

var zoom_level := 2.0
var zoom_min := 1.0
var zoom_max := 3.0
var zoom_factor := 0.1
var camera_speed := 20.0

func _ready() -> void:
	change_all_tiles_to_season("winter")
	camera.zoom = Vector2(zoom_level, zoom_level)

func _process(delta: float) -> void:
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
	var source_id := layer.get_cell_source_id(pos)
	var atlas_coords := layer.get_cell_atlas_coords(pos)
	var alternative_tile := layer.get_cell_alternative_tile(pos)
	
	if source_id == -1:
		return
	
	var current_season := "spring" if atlas_coords.y < 7 else "winter"
	if current_season == season: return
	
	match season:
		"winter":
			atlas_coords.y += 7
		"spring":
			atlas_coords.y -= 7
	
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
