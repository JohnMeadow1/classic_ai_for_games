extends Node2D
class_name VectorMap

const GRID_RES := 30
const WALKABLE_COST := 999
const BLOCKED_COST := 1000

var grid_size := Vector2i(30, 20)
var grid_cells := PackedInt32Array()
var vector_field := PackedVector2Array()
var edges: Array[Vector2i] = []

var navigation_target: Vector2i

var max_distance := -INF
@export var is_draw_grid: bool = true

func _ready() -> void:
	Steering.map = self
	grid_size = get_viewport().size / GRID_RES
	grid_cells.resize(grid_size.x * grid_size.y)
	vector_field.resize(grid_size.x * grid_size.y)
	

func set_target(in_position:Vector2) -> void:
	navigation_target = (in_position / GRID_RES).floor()
	max_distance = -INF
	edges.clear()
	for i in grid_cells.size():
		grid_cells[i] = WALKABLE_COST
	_rasterize_obstacles()
	 
	update_flow_field()
	queue_redraw()


func get_direction_vector(coords: Vector2) -> Vector2:
	coords = (coords/GRID_RES).floor()
	var cell := Vector2i(coords)
	if not _is_in_bounds(cell):
		return Vector2.ZERO

	var minimum := get_grid_value(cell.x, cell.y)
	var direction := Vector2.ZERO
	for neighbor_direction: Vector2i in [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN
	]:
		var neighbor := cell + neighbor_direction
		if not _is_in_bounds(neighbor):
			continue
		var neighbor_value := get_grid_value(neighbor.x, neighbor.y)
		if neighbor_value < minimum:
			minimum = neighbor_value
			direction = neighbor_direction
	return direction


func update_flow_field() -> void:
	var start_pos = navigation_target
	start_pos.x = clamp(start_pos.x, 0, grid_size.x-1)
	start_pos.y = clamp(start_pos.y, 0, grid_size.y-1)
	if get_grid_value(start_pos.x, start_pos.y) >= BLOCKED_COST:
		return
	set_grid_value(start_pos.x, start_pos.y, 0)
	edges.append(start_pos)
	
	var edge_index := 0
	while edge_index < edges.size():
		var current := edges[edge_index]
		var new_value = get_grid_value(current.x, current.y) + 1
		if new_value > max_distance:
			max_distance = new_value
		
		for neighbor_direction: Vector2i in [
			Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP
		]:
			var neighbor := current + neighbor_direction
			if not _is_in_bounds(neighbor):
				continue
			if get_grid_value(neighbor.x, neighbor.y) >= BLOCKED_COST:
				continue
			if get_grid_value(neighbor.x, neighbor.y) > new_value:
				edges.append(neighbor)
				set_grid_value(neighbor.x, neighbor.y, new_value)
		edge_index += 1


func _rasterize_obstacles() -> void:
	for obstacle in Steering.obstacle_node.get_children():
		if not obstacle is Node2D:
			continue
		var obstacle_position: Vector2 = obstacle.global_position
		for y in grid_size.y:
			for x in grid_size.x:
				var cell_center := Vector2(x + 0.5, y + 0.5) * GRID_RES
				if cell_center.distance_to(obstacle_position) <= Steering.obstacle_distance:
					grid_cells[x + y * grid_size.x] = BLOCKED_COST


func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 \
		and cell.x < grid_size.x and cell.y < grid_size.y

func get_grid_value(x: int, y: int) -> int:
	return grid_cells[x + y * grid_size.x]
	
func set_grid_value(x: int, y: int, value: int) -> void:
	grid_cells[x + y * grid_size.x] = value
	
func get_grid_valueV(coords: Vector2) -> int:
	var x := int(coords.x / GRID_RES)
	var y := int(coords.y / GRID_RES)
	return grid_cells[ x + y * grid_size.x ]
	
func set_grid_valueV(coords: Vector2, value: int) -> void:
	var x := int(coords.x / GRID_RES)
	var y := int(coords.y / GRID_RES)
	grid_cells[ x + y * grid_size.x ] = value

func _draw() -> void:
	if not is_draw_grid:
		return
		
	var rect := Rect2i()
	rect.size = Vector2i.ONE * GRID_RES

	for y in grid_size.y:
		for x in grid_size.x:
			rect.position = Vector2i(x, y) * GRID_RES
			var color = Color.from_hsv(float(get_grid_value(x,y))/max_distance, 1, 1, 0.2)
			draw_rect(rect, color, false)
