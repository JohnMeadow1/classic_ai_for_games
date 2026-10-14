extends Node2D

@export var debug = false
var border_margin = 100

var velocity    := Vector2.ZERO
var angle       := 0.0
var facing      := Vector2.ZERO

var steering    := Vector2.ZERO
var desired_velocity := Vector2.ZERO

var wander_angle  := 0.0
var circle_offset := 10.0
var circle_radius := 0.0
var circle_center := Vector2.ZERO

#var debug_separation := PackedVector2Array()
#var debug_cohesion   := PackedVector2Array()
@export var flock_id:int = 2
@export var is_predator:bool = false

func _ready():
	var margin = 20
	position.x = randf_range( margin, get_viewport().size.x - margin )
	position.y = randf_range( margin, get_viewport().size.y - margin )
	velocity = Vector2.RIGHT.rotated(randf()*TAU) * Globals.min_speed
	flock_id = randi() % 2
	$Sprite2D.modulate = Color.from_hsv(float(flock_id) * 0.25, 1.0, 1.0, 1.0)

func _process(delta: float) -> void:
	angle = velocity.angle()
	facing = velocity.normalized()
	$Sprite2D.rotation = angle
	
	#----------- tak
	steering = arrival( get_global_mouse_position() )
	steering += wander()
	#----------- albo tak
	#steering = wander()
	#-----------
	
	velocity += steering
	velocity = velocity.limit_length(Globals.max_speed)
	velocity -= velocity * delta
	handle_screen_edge()
	
	position += velocity * delta

	if debug: queue_redraw()

func wander() -> Vector2:
	circle_offset = 0.0
	circle_radius = Globals.separation_range
	circle_center = facing * (circle_radius + circle_offset)
	wander_angle += (randf() - 0.5) * 0.5
	var direction = circle_center + Vector2.RIGHT.rotated(wander_angle) * circle_radius
	#var speed_clamped = min (direction.length(), Globals.max_speed) 
	#desired_velocity = direction.normalized() * speed_clamped
	desired_velocity = direction
	return desired_velocity

func arrival(in_position:Vector2) -> Vector2:
	var direction := position.direction_to(in_position)
	var distance := position.distance_to(in_position)
	var arvial_range :float = Globals.view_range
	var arival_progress = min(distance / arvial_range, 1.0)
	desired_velocity = direction * Globals.max_speed * arival_progress
	return desired_velocity

func seek(in_position:Vector2) -> Vector2:
	desired_velocity = position.direction_to(in_position) * Globals.max_speed
	return desired_velocity

	
func flee(in_position:Vector2) -> Vector2:
	desired_velocity = in_position.direction_to(position) * Globals.max_speed
	return desired_velocity

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
		draw_circle( circle_center, Globals.separation_range, Color(0.0, 1.0, 1.0, 0.1))
		draw_line(circle_center, circle_center+Vector2.RIGHT.rotated(wander_angle) * circle_radius, Color(1.0, 1.0, 1.0, 0.2), 2.0)
		
		#draw_line(circle_center, circle_center + Vector2.RIGHT.rotated(wander_angle) * circle_radius, Color.WHITE, 2.0)
		#draw_circle(Vector2.RIGHT.rotated(wander_angle) * circle_radius, 4.0, Color.WHITE)
		draw_vector( steering, Color( 0.0, 1.0, 0.0, 0.3 ), 3 )
		draw_vector( desired_velocity, Color( 0.0, 0.0, 1.0, 0.3 ), 3 )
		
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



#func get_alignment():
	#boid_count = 0
	#var local_velocity = Vector2()
	#for boid in get_parent().get_children():
		#if boid != self:
			#var distance = (boid.position - self.position).length()
			#if distance <= Globals.view_range:
				#local_velocity += boid.velocity
				#boid_count += 1
	#if boid_count > 0:
		#local_velocity /= boid_count
	#
	#return local_velocity
#
#func get_cohesion():
	#boid_count = 0
	#var average_position = Vector2()
	#for boid in get_parent().get_children():
		#if boid != self:
			#var distance = (boid.position - self.position).length()
			#if distance <= Globals.view_range:
				#average_position += boid.position
				#boid_count += 1
	#if boid_count > 0:
		#average_position /= boid_count
		#
	#var vector_to_average_position = average_position - position
	#return  vector_to_average_position
#
#func get_separation():
	#boid_count = 0
	#var local_separation = Vector2()
	#for boid in get_parent().get_children():
		#if boid != self:
			#var vector_from = self.position - boid.position 
			#var distance = (vector_from).length()
			#if distance <= Globals.separation_range:
				#local_separation += vector_from.normalized() / distance
				#boid_count += 1
	#return local_separation





#func calculate_all():
	#alignment  = Vector2.ZERO
	#cohesion   = Vector2.ZERO
	#separation = Vector2.ZERO
	#boid_count = 0
	#var distance = 0.0
	#var angle_to = 0.0
	#if debug:
		#debug_separation.clear()
		#debug_cohesion.clear()
	#for boid in get_parent().get_children():
		#if boid != self and boid.flock_id == flock_id:
			#distance = (boid.position - self.position).length_squared()
			#angle_to = abs(velocity.angle_to(boid.position - self.position))
			#if angle_to < Globals.view_range_fov:
				#if distance <= Globals.view_range_squared:
					#alignment += boid.velocity
					#cohesion += boid.position
					#boid_count += 1
					#if debug:
						#debug_cohesion.push_back(boid.position)
			#if angle_to < Globals.separation_range_fov:
				#if distance <= Globals.separation_range_squared:
					#separation += (position - boid.position).normalized() / (position - boid.position).length()
					#if debug:
						#debug_separation.push_back(boid.position)
	#if boid_count > 1:
		#cohesion /= boid_count
		#cohesion -= self.position
		#
