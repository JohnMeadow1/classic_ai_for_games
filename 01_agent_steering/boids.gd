extends Node2D

@export var BOIDS_COUNT: int  = 50
var boid_object = load("res://boid.tscn")

func _ready():
	generate_boids()
	
func _process(_delta):
	get_parent().update_count(get_child_count())
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var new_boid = boid_object.instantiate()
			add_child(new_boid)
			new_boid.position = event.position
			
func generate_boids():
	for i in range ( BOIDS_COUNT ):
		var new_boid = boid_object.instantiate()
		add_child(new_boid)
		
		
