class_name FogOfWar
extends Node2D
"""玩家视角战争迷雾：实时视野、永久探索记录与敌方显隐。"""

const GRID := Vector2i(160, 90)
const UPDATE_INTERVAL := 0.15
const UNEXPLORED_COLOR := Color(0.055, 0.050, 0.045, 0.94)
const EXPLORED_COLOR := Color(0.14, 0.13, 0.12, 0.52)

var map_rect: Rect2
var _cell_size: Vector2
var _visible_cells := PackedByteArray()
var _explored_cells := PackedByteArray()
var _image: Image
var _texture: ImageTexture
var _overlay: Sprite2D
var _timer := 0.0


func setup(rect: Rect2) -> void:
	map_rect = rect
	_cell_size = rect.size / Vector2(GRID)
	_visible_cells.resize(GRID.x * GRID.y)
	_explored_cells.resize(GRID.x * GRID.y)
	_image = Image.create(GRID.x, GRID.y, false, Image.FORMAT_RGBA8)
	_image.fill(UNEXPLORED_COLOR)
	_texture = ImageTexture.create_from_image(_image)

	_overlay = Sprite2D.new()
	_overlay.centered = false
	_overlay.position = rect.position
	_overlay.scale = _cell_size
	_overlay.texture = _texture
	_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_overlay.z_as_relative = false
	_overlay.z_index = 90
	add_child(_overlay)


func _ready() -> void:
	add_to_group("fog_of_war")
	refresh_now()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= UPDATE_INTERVAL:
		_timer = 0.0
		refresh_now()


func refresh_now() -> void:
	if _image == null or not is_inside_tree():
		return
	_visible_cells.fill(0)
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is Unit and unit.alive and unit.team == 0:
			_mark_visible(unit.global_position, _source_radius(unit))
	for building in get_tree().get_nodes_in_group("buildings"):
		if building is Building and building.alive and building.team == 0:
			_mark_visible(building.global_position, _source_radius(building))
	_update_image()
	_update_enemy_visibility()


func is_currently_visible(world_pos: Vector2) -> bool:
	var cell := _world_to_cell(world_pos)
	return cell.x >= 0 and _visible_cells[_index(cell.x, cell.y)] == 1


func is_explored(world_pos: Vector2) -> bool:
	var cell := _world_to_cell(world_pos)
	return cell.x >= 0 and _explored_cells[_index(cell.x, cell.y)] == 1


func _mark_visible(world_pos: Vector2, radius: float) -> void:
	var local_pos := world_pos - map_rect.position
	var min_x := clampi(int(floor((local_pos.x - radius) / _cell_size.x)), 0, GRID.x - 1)
	var max_x := clampi(int(ceil((local_pos.x + radius) / _cell_size.x)), 0, GRID.x - 1)
	var min_y := clampi(int(floor((local_pos.y - radius) / _cell_size.y)), 0, GRID.y - 1)
	var max_y := clampi(int(ceil((local_pos.y + radius) / _cell_size.y)), 0, GRID.y - 1)
	var radius_sq := radius * radius
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var center := map_rect.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * _cell_size
			if center.distance_squared_to(world_pos) <= radius_sq:
				var i := _index(x, y)
				_visible_cells[i] = 1
				_explored_cells[i] = 1


func _update_image() -> void:
	for y in GRID.y:
		for x in GRID.x:
			var i := _index(x, y)
			var color := Color.TRANSPARENT
			if _visible_cells[i] == 0:
				color = EXPLORED_COLOR if _explored_cells[i] == 1 else UNEXPLORED_COLOR
			_image.set_pixel(x, y, color)
	_texture.update(_image)


func _update_enemy_visibility() -> void:
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is Unit:
			var detected: bool = bool(unit.stealthed) and _detected_by_watchtower(unit.global_position)
			unit.visible = true if unit.team == 0 else is_currently_visible(unit.global_position) and (not unit.stealthed or detected)
	for building in get_tree().get_nodes_in_group("buildings"):
		if building is Building:
			building.visible = true if building.team == 0 else is_currently_visible(building.global_position)


func _detected_by_watchtower(world_point: Vector2) -> bool:
	for building in get_tree().get_nodes_in_group("buildings"):
		if building is Building and building.alive and building.team == 0 and building.detects_stealth_at(world_point):
			return true
	return false


func _source_radius(source: Node2D) -> float:
	if source is Building:
		if not source.complete:
			return 220.0
		var def: Dictionary = Defs.building(source.def_id)
		if def.get("tower", false):
			return 520.0
		if def.get("dropoff", false):
			return 560.0
		return 380.0
	if source is Worker:
		return 270.0
	return 320.0


func _world_to_cell(world_pos: Vector2) -> Vector2i:
	if not map_rect.has_point(world_pos):
		return Vector2i(-1, -1)
	var local_pos := world_pos - map_rect.position
	return Vector2i(
		clampi(int(local_pos.x / _cell_size.x), 0, GRID.x - 1),
		clampi(int(local_pos.y / _cell_size.y), 0, GRID.y - 1))


func _index(x: int, y: int) -> int:
	return y * GRID.x + x
