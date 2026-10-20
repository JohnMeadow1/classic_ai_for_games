extends Node2D
class_name Botek

@export var debug = false
var border_margin = 100

var velocity    := Vector2.ZERO
var angle       := 0.0
var facing      := Vector2.ZERO

var steering    := Vector2.ZERO
var desired_velocity := Vector2.ZERO

var wander_angle       := 0.0
var circle_radius      := 0.0
var circle_center      := Vector2.ZERO
var circle_displacement := Vector2.ZERO
var precited_position := Vector2.ZERO
var siblings := [Botek]
var obstacles := [Node2D]

#var debug_separation := PackedVector2Array()
#var debug_cohesion   := PackedVector2Array()
@export var flock_id:int = 2
@export var is_predator:bool = false

@export_group("Behavior tuning")
@export var max_steering_force     := 300.0
@export var wander_distance        := 60.0
@export var wander_radius          := 30.0
@export var wander_jitter          := 2.0
@export var max_see_ahead          := 60.0
@export var max_avoid_force        := 150.0
@export var path_arrive_radius     := 20.0
@export var leader_behind_distance := 40.0
@export var leader_sight_radius    := 50.0
@export var queue_ahead_distance   := 25.0
@export var queue_radius           := 25.0
@export var queue_brake_strength   := 0.8

var path_index := 0

func _ready():
	var margin = 20
	position.x = randf_range( margin, get_viewport().size.x - margin )
	position.y = randf_range( margin, get_viewport().size.y - margin )
	velocity = Vector2.RIGHT.rotated(randf()*TAU) * Globals.min_speed
	flock_id = randi() % 2
	$Sprite2D.modulate = Color.from_hsv(float(is_predator) * 0.25, 1.0, 1.0, 1.0)
	
	siblings = get_boids()
	obstacles = Globals.obstacle_node.get_children()

func _process(delta: float) -> void:
	angle = velocity.angle()
	facing = velocity.normalized()
	$Sprite2D.rotation = angle
	
	steering = arrival( get_global_mouse_position() )
	#steering += wander(delta)
	#steering += flee(get_viewport_rect().size*0.5)
	steering += collision_avoidance(100.0)
				
	steering = steering.limit_length(max_steering_force)
	
	velocity += steering * delta
	velocity = velocity.limit_length(Globals.max_speed)
	velocity -= velocity * Globals.friction * delta
	handle_screen_edge()
	
	position += velocity * delta

	if debug: queue_redraw()

func steer_toward(in_desired_velocity: Vector2) -> Vector2:
	desired_velocity = in_desired_velocity
	return desired_velocity - velocity

func wander(delta: float) -> Vector2:
	var wander_facing := facing
	wander_angle += (randf() - 0.5) * 5.0 * delta
	circle_radius = 40.0
	circle_center = wander_facing * (circle_radius + 10.0)
	circle_displacement = Vector2.RIGHT.rotated(wander_angle) * circle_radius
	
	var target_velocity := circle_center + circle_displacement
	return steer_toward(target_velocity)

func arrival(in_position: Vector2) -> Vector2:
	var direction := position.direction_to(in_position)
	var distance := position.distance_to(in_position)
	var arrival_range := maxf(Globals.view_range, 0.001)
	var arrival_progress := minf(distance / arrival_range, 1.0)
	var target_velocity := direction * Globals.max_speed * arrival_progress
	return steer_toward(target_velocity)

func seek(in_position: Vector2) -> Vector2:
	var target_velocity := position.direction_to(in_position) * Globals.max_speed
	return steer_toward(target_velocity)

	
func flee(in_position: Vector2) -> Vector2:
	var target_velocity := in_position.direction_to(position) * Globals.max_speed
	return steer_toward(target_velocity)

func pursuit(in_position:Vector2, in_velocity:Vector2) -> Vector2:
	return seek(predict_position(in_position, in_velocity))

func evade(in_position:Vector2, in_velocity:Vector2) -> Vector2:
	return flee(predict_position(in_position, in_velocity))


func predict_position(in_position:Vector2, in_velocity:Vector2) -> Vector2:
	var prediction_time := 0.0
	prediction_time = position.distance_to(in_position) / Globals.max_speed
	precited_position = in_velocity * prediction_time
	return in_position + precited_position
	
func collision_avoidance(obstacle_radius:float) -> Vector2:
	var speed_ratio := velocity.length() / maxf(Globals.max_speed, 0.001)
	var ahead := position + facing * max_see_ahead * speed_ratio
	var ahead_half := position + facing * max_see_ahead * speed_ratio * 0.5

	var most_threatening :Node2D = null
	var threat_distance := 0.0
	for obstacle in obstacles:
		var obstacle_position: Vector2 = obstacle.position
		var blocks_path := obstacle_position.distance_to(ahead) <= obstacle_radius \
			or obstacle_position.distance_to(ahead_half) <= obstacle_radius \
			or obstacle_position.distance_to(position) <= obstacle_radius
		if not blocks_path:
			continue

		var distance := position.distance_to(obstacle_position)
		if most_threatening == null or distance < threat_distance:
			most_threatening = obstacle
			threat_distance = distance

	if most_threatening == null:
		return Vector2.ZERO

	var target_velocity: Vector2 = (ahead - most_threatening.position).normalized()
	target_velocity *= Globals.max_speed
	
	return steer_toward(target_velocity).limit_length(max_avoid_force)

func get_neighbor_ahead():
	var ahead := position + facing * queue_ahead_distance
	for boid in siblings:
		if boid.position.distance_to(ahead) <= queue_radius:
			return boid
	return null

func get_boids() -> Array[Botek]:
	var boids := []
	for node in get_parent().get_children():
		if node == self:
			continue
		boids.append(node)
	return boids

func get_neighbors(range_squared: float, field_of_view: float) -> Array:
	var neighbors := [Botek]
	for boid in siblings:
		if boid.flock_id != flock_id:
			continue

		var offset: Vector2 = boid.position - position
		if offset.length_squared() == 0.0:
			continue
		if offset.length_squared() > range_squared:
			continue
		if abs(facing.angle_to(offset)) > field_of_view:
			continue

		neighbors.append(boid)
	return neighbors

func handle_screen_edge():
	if Globals.space_wrap:
		if position.x > get_viewport().size.x:
			position.x = 0
		if position.y > get_viewport().size.y:
			position.y = 0
		if position.x < 0: 
			position.x = get_viewport().size.x
		if position.y < 0:
			position.y = get_viewport().size.y
	else:
		if position.x + border_margin > get_viewport().size.x:
			velocity.x -= (border_margin - (get_viewport().size.x - position.x)) * 0.2
		if position.y + border_margin > get_viewport().size.y:
			velocity.y -= (border_margin - (get_viewport().size.y - position.y)) * 0.2
	
		if position.x - border_margin < 0:
			velocity.x += (border_margin - position.x) * 0.2
		if position.y - border_margin < 0:
			velocity.y += (border_margin - position.y) * 0.2

func _draw():
	if debug:
		draw_circle( Vector2.ZERO, Globals.view_range, Color(1.0, 1.0, 1.0, 0.1))
		draw_circle( circle_center, circle_radius, Color(0.0, 1.0, 1.0, 0.1))
		draw_line(circle_center, circle_center + circle_displacement, Color(1.0, 1.0, 1.0, 0.2), 2.0)
		
		draw_vector( steering, Color( 0.0, 1.0, 0.0, 0.3 ), 3 )
		draw_vector( desired_velocity, Color( 0.0, 0.0, 1.0, 0.3 ), 3 )
		draw_vector( precited_position, Color(0.982, 0.0, 0.115, 0.3), 3 )
		
func draw_vector( vector, color, arrow_size ):
	if vector.length_squared() > 1:
		var points    = []
		var direction = vector.normalized()
		points.push_back( vector + direction * arrow_size * 2 )
		points.push_back( vector + direction.rotated(  PI / 2 ) * arrow_size )
		points.push_back( vector + direction.rotated( -PI / 2 ) * arrow_size )
		draw_polygon( PackedVector2Array( points ), PackedColorArray( [color] ) )
		draw_line( Vector2( 0.0, 0.0 ), vector, color, arrow_size )

func draw_poly_arc( radius, in_angle, fov, resolution, color ):
	var step = fov / resolution * 2
	var points_arc = PackedVector2Array()
	points_arc.push_back(Vector2.ZERO)
	var colors = PackedColorArray()
	colors.push_back(color)

	for i in range(resolution + 1):
		var angle_point = in_angle + step * i - fov
		points_arc.push_back( Vector2(cos(angle_point), sin(angle_point)) * radius)
		colors.push_back(color)
		
	draw_polygon(points_arc, colors)

#func predict_position(in_position:Vector2, in_velocity:Vector2) -> Vector2:
#	var prediction_time := 0.0
#	prediction_time = (position.distance_to(in_position) / maxf(Globals.max_speed, 0.001))
#	return in_position + in_velocity * prediction_time

#func wander(delta: float) -> Vector2:
#	var wander_facing := facing
#	if wander_facing == Vector2.ZERO:
#		wander_facing = Vector2.RIGHT.rotated(angle)
#
#	circle_radius = wander_radius
#	circle_center = wander_facing * wander_distance
#	wander_angle += randf_range(-wander_jitter, wander_jitter) * delta
#	circle_displacement = wander_facing.rotated(wander_angle) * circle_radius
#	var target_velocity := (
#		(circle_center + circle_displacement).normalized()
#		* Globals.max_speed
#	)
#	return steer_toward(target_velocity)

#func collision_avoidance(obstacles:Array, obstacle_radius:float) -> Vector2:
#	if facing == Vector2.ZERO:
#		return Vector2.ZERO
#
#	var speed_ratio := velocity.length() / maxf(Globals.max_speed, 0.001)
#	var ahead := position + facing * max_see_ahead * speed_ratio
#	var ahead_half := position + facing * max_see_ahead * speed_ratio * 0.5
#
#	var most_threatening = null
#	var threat_distance := 0.0
#	for obstacle in obstacles:
#		if obstacle == self:
#			continue
#
#		var obstacle_position: Vector2 = obstacle.position
#		var blocks_path := obstacle_position.distance_to(ahead) <= obstacle_radius \
#			or obstacle_position.distance_to(ahead_half) <= obstacle_radius \
#			or obstacle_position.distance_to(position) <= obstacle_radius
#		if not blocks_path:
#			continue
#
#		var distance := position.distance_to(obstacle_position)
#		if most_threatening == null or distance < threat_distance:
#			most_threatening = obstacle
#			threat_distance = distance
#
#	if most_threatening == null:
#		return Vector2.ZERO
#
#	var target_velocity: Vector2 = (
#		(ahead - most_threatening.position).normalized()
#		* Globals.max_speed
#	)
#	return steer_toward(target_velocity).limit_length(max_avoid_force)

#func path_follow(path:PackedVector2Array, loop := false) -> Vector2:
#	if path.is_empty():
#		return Vector2.ZERO
#
#	path_index = clampi(path_index, 0, path.size() - 1)
#	var is_last_waypoint := path_index == path.size() - 1
#
#	if position.distance_to(path[path_index]) <= path_arrive_radius:
#		if not is_last_waypoint:
#			path_index += 1
#		elif loop:
#			path_index = 0
#		is_last_waypoint = path_index == path.size() - 1
#
#	if is_last_waypoint and not loop:
#		return arrival(path[path_index])
#	return seek(path[path_index])

#func follow_leader(leader) -> Vector2:
#	var leader_facing: Vector2 = leader.velocity.normalized()
#	if leader_facing == Vector2.ZERO:
#		leader_facing = Vector2.RIGHT.rotated(leader.angle)
#
#	var leader_offset := leader_facing * leader_behind_distance
#	var behind_leader: Vector2 = leader.position - leader_offset
#	var ahead_of_leader: Vector2 = leader.position + leader_offset
#
#	var force := Vector2.ZERO
#	if position.distance_to(ahead_of_leader) <= leader_sight_radius:
#		force += evade(leader.position, leader.velocity)
#	force += arrival(behind_leader)
#	force += separation()
#
#	desired_velocity = velocity + force
#	return force

#func queue(in_steering:Vector2) -> Vector2:
#	if get_neighbor_ahead() == null:
#		return in_steering
#
#	var braking_force := -velocity * queue_brake_strength
#	var force := in_steering + braking_force + separation()
#	desired_velocity = velocity + force
#	return force


#func alignment() -> Vector2:
#	var neighbors := get_neighbors(Globals.view_range_squared, Globals.view_range_fov)
#	if neighbors.is_empty():
#		return Vector2.ZERO
#
#	var average_velocity := Vector2.ZERO
#	for boid in neighbors:
#		average_velocity += boid.velocity
#	average_velocity /= neighbors.size()
#
#	var target_velocity := average_velocity.normalized() * Globals.max_speed
#	return steer_toward(target_velocity)
#
#func cohesion() -> Vector2:
#	var neighbors := get_neighbors(Globals.view_range_squared, Globals.view_range_fov)
#	if neighbors.is_empty():
#		return Vector2.ZERO
#
#	var center_of_mass := Vector2.ZERO
#	for boid in neighbors:
#		center_of_mass += boid.position
#	center_of_mass /= neighbors.size()
#
#	var target_velocity := position.direction_to(center_of_mass) * Globals.max_speed
#	return steer_toward(target_velocity)
#
#func separation() -> Vector2:
#	var neighbors := get_neighbors(
#		Globals.separation_range_squared,
#		Globals.separation_range_fov
#	)
#	if neighbors.is_empty():
#		return Vector2.ZERO
#
#	var escape_direction := Vector2.ZERO
#	for boid in neighbors:
#		var offset: Vector2 = position - boid.position
#		escape_direction += offset.normalized() / offset.length()
#
#	var target_velocity := escape_direction.normalized() * Globals.max_speed
#	return steer_toward(target_velocity)
