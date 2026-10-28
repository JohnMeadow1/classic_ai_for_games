extends Node2D
class_name Botek

enum Behavior { SEEK, FLEE, ARRIVAL, WANDER, PURSUIT, EVADE, PATH_FOLLOW, FOLLOW_LEADER, QUEUE }

const BEHAVIOR_SCRIPTS := {
	Behavior.SEEK: preload("res://behaviors/SeekBehavior.gd"),
	Behavior.FLEE: preload("res://behaviors/FleeBehavior.gd"),
	Behavior.ARRIVAL: preload("res://behaviors/ArrivalBehavior.gd"),
	Behavior.WANDER: preload("res://behaviors/WanderBehavior.gd"),
	Behavior.PURSUIT: preload("res://behaviors/PursuitBehavior.gd"),
	Behavior.EVADE: preload("res://behaviors/EvadeBehavior.gd"),
	Behavior.PATH_FOLLOW: preload("res://behaviors/PathFollowBehavior.gd"),
	Behavior.FOLLOW_LEADER: preload("res://behaviors/FollowLeaderBehavior.gd"),
	Behavior.QUEUE: preload("res://behaviors/QueueBehavior.gd")
}

var border_margin = 100

var velocity    := Vector2.ZERO
var angle       := 0.0
var facing      := Vector2.ZERO

var steering    := Vector2.ZERO
var desired_velocity := Vector2.ZERO

var circle_center      := Vector2.ZERO
var circle_displacement := Vector2.ZERO
var precited_position := Vector2.ZERO
var is_selected := false

@export var is_predator:bool = false
@export var behavior: Behavior = Behavior.WANDER:
	set(value):
		if is_instance_valid(state_machine) and state_machine.is_configured:
			if state_machine.change_behavior(value):
				behavior = value
		else:
			behavior = value

@export var collision_avoidance_enabled := true
@export var target_agent: Botek

var destination := Vector2.ZERO
var has_destination := false

var has_target_order := false
var path_index := 0
var path :PackedVector2Array

@onready var state_machine: AgentStateMachine = $StateMachine
@onready var debug_draw: Node2D = $DebugDraw

func _ready():
	state_machine.configure(self, BEHAVIOR_SCRIPTS)
	state_machine.change_behavior(behavior)
	velocity = Vector2.RIGHT.rotated(randf()*TAU) * Steering.max_speed / 60.0
	update_behavior_label()
	update_name_label()

func add_path_point(in_position:Vector2):
	path.append(in_position)

func issue_destination_order(in_position: Vector2) -> void:
	has_destination = true
	has_target_order = false
	target_agent = null
	set_predator(false)
	destination = in_position
	add_path_point(in_position)
	behavior = Behavior.PATH_FOLLOW

func issue_follow_order(target: Botek) -> void:
	has_destination = false
	has_target_order = true
	target_agent = target
	set_predator(true)
	behavior = Behavior.FOLLOW_LEADER

func set_behavior_and_clear_order(new_behavior: Behavior, update_predator := true) -> void:
	has_destination = false
	has_target_order = false
	behavior = new_behavior
	if update_predator:
		set_predator(new_behavior == Behavior.PURSUIT)

func set_automatic_target(target: Botek) -> void:
	has_target_order = false
	target_agent = target

func update_name_label() -> void:
	%NameLabel.text = name

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
		if target_agent and behavior in [Behavior.EVADE, Behavior.PURSUIT, Behavior.FOLLOW_LEADER]:
			%BehaviorLabel.text += " -> " + target_agent.name

func set_selected(selected: bool) -> void:
	is_selected = selected
	debug_draw.queue_redraw()

func request_behavior(behavior_name: String) -> void:
	var behavior_index := Behavior.keys().find(behavior_name)
	if behavior_index < 0:
		push_warning("Ignoring unknown steering behavior: %s" % behavior_name)
		return
	behavior = behavior_index as Behavior

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

func calculate_steering(delta: float) -> Vector2:
	return state_machine.calculate_steering(delta)

func calculate_wander(delta: float) -> Vector2:
	return state_machine.calculate_behavior(Behavior.WANDER, delta)

func steer_toward(in_desired_velocity: Vector2) -> Vector2:
	desired_velocity = in_desired_velocity
	return desired_velocity - velocity

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


func alignment() -> Vector2:
	var neighbors := get_neighbors(Steering.view_range_squared, Steering.view_range_fov)
	if neighbors.is_empty():
		return Vector2.ZERO

	var average_velocity := Vector2.ZERO
	for boid in neighbors:
		average_velocity += boid.velocity
	average_velocity /= neighbors.size()

	var target_velocity := average_velocity.normalized() * Steering.max_speed
	return steer_toward(target_velocity)

func cohesion() -> Vector2:
	var neighbors := get_neighbors(Steering.view_range_squared, Steering.view_range_fov)
	if neighbors.is_empty():
		return Vector2.ZERO

	var center_of_mass := Vector2.ZERO
	for boid in neighbors:
		center_of_mass += boid.position
	center_of_mass /= neighbors.size()

	var target_velocity := position.direction_to(center_of_mass) * Steering.max_speed
	return steer_toward(target_velocity)

func separation() -> Vector2:
	var neighbors := get_neighbors(
		Steering.separation_range_squared,
		Steering.separation_range_fov
	)
	if neighbors.is_empty():
		return Vector2.ZERO

	var escape_direction := Vector2.ZERO
	for boid in neighbors:
		var offset: Vector2 = position - boid.position
		escape_direction += offset.normalized() / offset.length()

	var target_velocity := escape_direction.normalized() * Steering.max_speed
	return steer_toward(target_velocity)
