extends Node2D

var velocity = Vector2.ZERO
var angular_velocity = 0.0
var impulse = Vector2.ZERO
var center_of_mass = Vector2.ZERO
var thrust_vector  = Vector2(0, -1)

func _physics_process(delta):
	thrust_vector = $Marker2D.global_position - $Position2D2.global_position
	impulse = thrust_vector.cross($Marker2D.global_position - position) *0.01
	angular_velocity += impulse * delta
	angular_velocity *=0.9
	velocity += thrust_vector
	velocity *= 0.9
	position += velocity * delta
	rotation += angular_velocity * delta

func _draw():
	draw_line($Marker2D.position, $Marker2D.position - thrust_vector *10, Color.WHITE,3 )
