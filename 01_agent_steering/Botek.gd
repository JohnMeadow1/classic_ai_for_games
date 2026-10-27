extends Node2D
class_name Botek

enum Behavior { SEEK, FLEE, ARRIVAL, WANDER, PURSUIT, EVADE }

var border_margin = 100

var velocity    := Vector2.ZERO
var angle       := 0.0
var facing      := Vector2.ZERO

var steering    := Vector2.ZERO
var desired_velocity := Vector2.ZERO

var wander_angle       := 0.0
var circle_center      := Vector2.ZERO
var circle_displacement := Vector2.ZERO
var precited_position := Vector2.ZERO
var is_selected := false

@export var is_predator:bool = false
@export var behavior: Behavior = Behavior.ARRIVAL
@export var collision_avoidance_enabled := true
@export var target_agent: Botek

var path_index := 0

func _ready():
	velocity = Vector2.RIGHT.rotated(randf()*TAU) * Steering.max_speed
	update_behavior_label()

func get_behavior_name() -> String:
	var behavior_name: String = Behavior.keys()[behavior].capitalize()
	var needs_target := behavior == Behavior.PURSUIT or behavior == Behavior.EVADE
	if needs_target and not (is_instance_valid(target_agent) and target_agent != self):
		return "%s (no target: Wander)" % behavior_name
	return behavior_name

func update_behavior_label() -> void:
	var label_text := get_behavior_name()
	if %BehaviorLabel.text != label_text:
		%BehaviorLabel.text = label_text

func set_predator(in_bool:bool):
	is_predator = in_bool
	if is_predator:
		$Sprite2D.modulate = Color(1.0, 0.25, 0.15)
	else:
		$Sprite2D.modulate = Color.from_hsv(0.25, 1.0, 1.0, 1.0)

func _process(delta: float) -> void:
	angle = velocity.angle()
	facing = velocity.normalized()
	$Sprite2D.rotation = angle

	steering = calculate_steering(delta)
	update_behavior_label()
	
	if collision_avoidance_enabled:
		steering += collision_avoidance()
		
	steering = steering.limit_length(Steering.max_steering_force)

	velocity += steering * delta
	velocity = velocity.limit_length(Steering.max_speed)
	velocity -= velocity * delta
	handle_screen_edge()
	
	position += velocity * delta

	if Steering.debug_draw: queue_redraw()

func calculate_steering(delta: float) -> Vector2:
	var mouse_position := get_global_mouse_position()
	match behavior:
		Behavior.SEEK:
			return seek(mouse_position)
		Behavior.FLEE:
			return flee(mouse_position)
		Behavior.ARRIVAL:
			return arrival(mouse_position)
		Behavior.WANDER:
			return wander(delta)
		Behavior.PURSUIT:
			if is_instance_valid(target_agent) and target_agent != self:
				return pursuit(target_agent.position, target_agent.velocity)
			return wander(delta)
		Behavior.EVADE:
			if is_instance_valid(target_agent) and target_agent != self:
				return evade(target_agent.position, target_agent.velocity)
			return wander(delta)
	return Vector2.ZERO

func steer_toward(in_desired_velocity: Vector2) -> Vector2:
	desired_velocity = in_desired_velocity
	return desired_velocity - velocity

func wander(delta: float) -> Vector2:
	wander_angle += randf_range(-Steering.wander_jitter, Steering.wander_jitter) * delta
	circle_center = facing * Steering.wander_distance
	circle_displacement = Vector2.RIGHT.rotated(wander_angle) * Steering.wander_radius
	
	var target_velocity := circle_center + circle_displacement
	return steer_toward(target_velocity)

func arrival(in_position: Vector2) -> Vector2:
	var direction := position.direction_to(in_position)
	var distance := position.distance_to(in_position)
	var arrival_range := maxf(Steering.view_range, 0.001)
	var arrival_progress := minf(distance / arrival_range, 1.0)
	var target_velocity := direction * Steering.max_speed * arrival_progress
	return steer_toward(target_velocity)

func seek(in_position: Vector2) -> Vector2:
	var target_velocity := position.direction_to(in_position) * Steering.max_speed
	return steer_toward(target_velocity)

	
func flee(in_position: Vector2) -> Vector2:
	var target_velocity := in_position.direction_to(position) * Steering.max_speed
	return steer_toward(target_velocity)

func pursuit(in_position:Vector2, in_velocity:Vector2) -> Vector2:
	return seek(predict_position(in_position, in_velocity))

func evade(in_position:Vector2, in_velocity:Vector2) -> Vector2:
	return flee(predict_position(in_position, in_velocity))

#func predict_position(in_position:Vector2, in_velocity:Vector2) -> Vector2:
#	var distance := position.distance_to(in_position) 
#	var speed := velocity.length()
#	var t :float = distance / speed
#	precited_position = in_position + in_velocity * t
#	return precited_position
	
func predict_position(in_position:Vector2, in_velocity:Vector2) -> Vector2:
	var prediction_time := 0.0
	prediction_time = position.distance_to(in_position) / Steering.max_speed
	precited_position = in_velocity * prediction_time
	return in_position + precited_position

func collision_avoidance() -> Vector2:
	var speed_ratio := velocity.length() / maxf(Steering.max_speed, 0.001)
	var ahead := position + facing * Steering.max_see_ahead * speed_ratio
	var ahead_half := position + facing * Steering.max_see_ahead * speed_ratio * 0.5

	var most_threatening :Node2D = null
	var threat_distance := 0.0
	if not is_instance_valid(Steering.obstacle_node):
		return Vector2.ZERO

	for obstacle in Steering.obstacle_node.get_children():
		if not obstacle is Node2D:
			continue
		var obstacle_position: Vector2 = obstacle.position
		var blocks_path := obstacle_position.distance_to(ahead) <= Steering.obstacle_distance \
			or obstacle_position.distance_to(ahead_half) <= Steering.obstacle_distance \
			or obstacle_position.distance_to(position) <= Steering.obstacle_distance
		if not blocks_path:
			continue

		var distance := position.distance_to(obstacle_position)
		if most_threatening == null or distance < threat_distance:
			most_threatening = obstacle
			threat_distance = distance

	if most_threatening == null:
		return Vector2.ZERO

	var target_velocity: Vector2 = (ahead - most_threatening.position).normalized()
	target_velocity *= Steering.max_speed
	
	return steer_toward(target_velocity).limit_length(Steering.max_avoid_force)

func get_neighbor_ahead():
	var ahead := position + facing * Steering.queue_ahead_distance
	for boid in get_boids():
		if boid.position.distance_to(ahead) <= Steering.queue_radius:
			return boid
	return null

func get_boids() -> Array[Botek]:
	var boids: Array[Botek] = []
	for node in get_parent().get_children():
		if node == self:
			continue
		boids.append(node)
	return boids

func get_neighbors(range_squared: float, field_of_view: float) -> Array:
	var neighbors: Array[Botek] = []
	for boid in get_boids():

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
	if Steering.space_wrap:
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
	if is_selected:
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color.YELLOW, 2.0)
	if Steering.debug_draw:
		draw_circle(Vector2.ZERO, Steering.view_range, Color(1.0, 1.0, 1.0, 0.1))
		draw_circle(circle_center, Steering.wander_radius, Color(0.0, 1.0, 1.0, 0.1))
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
#	prediction_time = position.distance_to(in_position) / Steering.max_speed
#	precited_position = in_velocity * prediction_time
#	return in_position + precited_position


#func collision_avoidance(obstacle_radius:float) -> Vector2:
#	var speed_ratio := velocity.length() / maxf(Steering.max_speed, 0.001)
#	var ahead := position + facing * Steering.max_see_ahead * speed_ratio
#	var ahead_half := position + facing * Steering.max_see_ahead * speed_ratio * 0.5
#
#	var most_threatening :Node2D = null
#	var threat_distance := 0.0
#	if not is_instance_valid(Steering.obstacle_node):
#		return Vector2.ZERO
#
#	for obstacle in Steering.obstacle_node.get_children():
#		if not obstacle is Node2D:
#			continue
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
#	var target_velocity: Vector2 = (ahead - most_threatening.position).normalized()
#	target_velocity *= Steering.max_speed
#	
#	return steer_toward(target_velocity).limit_length(Steering.max_avoid_force)

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
#	var neighbors := get_neighbors(Steering.view_range_squared, Steering.view_range_fov)
#	if neighbors.is_empty():
#		return Vector2.ZERO
#
#	var average_velocity := Vector2.ZERO
#	for boid in neighbors:
#		average_velocity += boid.velocity
#	average_velocity /= neighbors.size()
#
#	var target_velocity := average_velocity.normalized() * Steering.max_speed
#	return steer_toward(target_velocity)
#
#func cohesion() -> Vector2:
#	var neighbors := get_neighbors(Steering.view_range_squared, Steering.view_range_fov)
#	if neighbors.is_empty():
#		return Vector2.ZERO
#
#	var center_of_mass := Vector2.ZERO
#	for boid in neighbors:
#		center_of_mass += boid.position
#	center_of_mass /= neighbors.size()
#
#	var target_velocity := position.direction_to(center_of_mass) * Steering.max_speed
#	return steer_toward(target_velocity)
#
#func separation() -> Vector2:
#	var neighbors := get_neighbors(
#		Steering.separation_range_squared,
#		Steering.separation_range_fov
#	)
#	if neighbors.is_empty():
#		return Vector2.ZERO
#
#	var escape_direction := Vector2.ZERO
#	for boid in neighbors:
#		var offset: Vector2 = position - boid.position
#		escape_direction += offset.normalized() / offset.length()
#
#	var target_velocity := escape_direction.normalized() * Steering.max_speed
#	return steer_toward(target_velocity)
