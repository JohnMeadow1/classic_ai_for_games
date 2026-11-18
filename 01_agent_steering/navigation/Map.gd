extends Node2D
class_name VectorMap

const GRID_RES  := 30

var grid_size := Vector2i(30, 20)
var grid_cells := PackedInt32Array()
var vector_field := PackedVector2Array()
var edges := PackedVector2Array()

var navigation_target:Vector2i

var max_distance := -INF
@export var is_draw_grid:bool = true

func _ready() -> void:
	Steering.map = self
	grid_size = get_viewport().size / GRID_RES
	grid_cells.resize(grid_size.x * grid_size.y)
	vector_field.resize(grid_size.x * grid_size.y)
	

func set_target(in_position:Vector2) -> void:
	navigation_target = (in_position / GRID_RES).floor()
	max_distance = -INF
	for i in grid_cells.size():
		if grid_cells[i] < 1000:
			grid_cells[i] = 999
	 
	update_flow_field()
	queue_redraw()


func get_direction_vector( coords:Vector2 ) -> Vector2:
	coords = (coords/GRID_RES).floor()
	var minimum = get_grid_value(coords.x, coords.y)
	var direction = Vector2(0,0)
	if get_grid_value(coords.x-1, coords.y) <= minimum:
		minimum = get_grid_value(coords.x-1, coords.y)
		direction += Vector2(-1,0)
	if get_grid_value(coords.x+1, coords.y) <= minimum:
		minimum = get_grid_value(coords.x+1, coords.y)
		direction += Vector2(1,0)
	if get_grid_value(coords.x, coords.y-1) <= minimum:
		minimum = get_grid_value(coords.x, coords.y-1)
		direction += Vector2(0,-1)
	if get_grid_value(coords.x, coords.y+1) <= minimum:
		minimum= get_grid_value(coords.x, coords.y+1)
		direction += Vector2(0,1)
	return direction

func update_flow_field() -> void:
	var start_pos = navigation_target
#	var start_pos = (get_global_mouse_position()/GRID_RES).floor()
	start_pos.x = clamp(start_pos.x, 0, grid_size.x-1)
	start_pos.y = clamp(start_pos.y, 0, grid_size.y-1)
	set_grid_value(start_pos.x, start_pos.y, 0)
	edges.append(start_pos)
	

#	if edges.size() > 0:
	while edges.size() > 0:
		var new_value = get_grid_value(edges[0].x , edges[0].y) + 1
		print(new_value)
		if new_value > max_distance:
			max_distance = new_value
		
		if edges[0].x+1 < grid_size.x && get_grid_value(edges[0].x+1 , edges[0].y) < 1000 :
			if get_grid_value(edges[0].x+1 , edges[0].y) > new_value:
				edges.append(Vector2(edges[0].x+1,edges[0].y))
				set_grid_value(edges[0].x+1, edges[0].y, new_value)
			
		if edges[0].y+1 < grid_size.y && get_grid_value(edges[0].x , edges[0].y+1) < 1000 :
			if get_grid_value(edges[0].x , edges[0].y+1) > new_value:
				edges.append(Vector2(edges[0].x,edges[0].y+1))
				set_grid_value(edges[0].x, edges[0].y+1, new_value)
			
		if edges[0].x-1 >= 0 && get_grid_value(edges[0].x-1 , edges[0].y) < 1000 :
			if get_grid_value(edges[0].x-1 , edges[0].y) > new_value:
				edges.append(Vector2(edges[0].x-1,edges[0].y))
				set_grid_value(edges[0].x-1, edges[0].y, new_value)
			
		if edges[0].y-1 >= 0 && get_grid_value(edges[0].x , edges[0].y-1) < 1000 :
			if get_grid_value(edges[0].x , edges[0].y-1) > new_value:
				edges.append(Vector2(edges[0].x,edges[0].y-1))
				set_grid_value(edges[0].x, edges[0].y-1, new_value)
		
		edges.remove_at(0)

func get_grid_value( x:float, y:float ):
	return grid_cells[ int(x) + int(y) * grid_size.x ]
	
func set_grid_value( x:float, y:float, value:int ):
	grid_cells[ int(x) + int(y) * grid_size.x ] = value
	
func get_grid_valueV( coords:Vector2 ):
	var x := int(coords.x / GRID_RES)
	var y := int(coords.y / GRID_RES)
	return grid_cells[ x + y * grid_size.x ]
	
func set_grid_valueV( coords:Vector2, value:int ):
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
			var color = Color.from_hsv(float(get_grid_value(x,y))/max_distance,1,1, 0.2)
			draw_rect(rect, color, false)
