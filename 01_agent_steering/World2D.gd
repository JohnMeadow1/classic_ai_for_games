extends Node2D
class_name BoidController

signal agent_count_changed(count: int)
signal selected_agent_changed(agent: Botek)

@export var BOIDS_COUNT: int = 50
@export var botek_scene: PackedScene = preload("res://Botek.tscn")

var agents: Array[Botek] = []
var selected_agent: Botek
var current_behavior := Botek.Behavior.ARRIVAL
var selected_only := false
var collision_avoidance_enabled := true

func _ready() -> void:
	add_to_group("agent_controller")
	for child in get_children():
		if child is Botek:
			register_agent(child)
	set_agent_count(maxi(BOIDS_COUNT, agents.size()))
	refresh_targets()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var click_position := get_global_mouse_position()
	if Input.is_key_pressed(KEY_SHIFT):
		spawn_agent(to_local(click_position))
	else:
		select_nearest_agent(click_position)

func set_agent_count(target_count: int) -> void:
	target_count = maxi(target_count, 0)
	while agents.size() < target_count:
		spawn_agent(random_spawn_position(), false)
	while agents.size() > target_count:
		var removed_agent :Botek= agents.pop_back()
		if removed_agent == selected_agent:
			set_selected_agent(null)
		removed_agent.queue_free()
	refresh_targets()
	agent_count_changed.emit(agents.size())

func spawn_agent(spawn_position: Vector2, notify := true) -> Botek:
	var new_agent := botek_scene.instantiate() as Botek
	if new_agent == null:
		push_error("The configured boid scene root must use boid.gd.")
		return null

	new_agent.position = spawn_position
	if new_agent.is_predator:
		new_agent.behavior = new_agent.Behavior.PURSUIT
	else:
		new_agent.behavior = new_agent.Behavior.EVADE
	new_agent.collision_avoidance_enabled = collision_avoidance_enabled
	#new_agent.debug = false
	add_child(new_agent)
	register_agent(new_agent, notify)
	refresh_targets()
	return new_agent

func register_agent(agent: Botek, notify := true) -> void:
	if agents.has(agent):
		return
	agents.append(agent)
	agent.collision_avoidance_enabled = collision_avoidance_enabled
	agent.tree_exiting.connect(_on_agent_exiting.bind(agent), CONNECT_ONE_SHOT)
	if notify:
		agent_count_changed.emit(agents.size())

func _on_agent_exiting(agent: Botek) -> void:
	agents.erase(agent)
	if selected_agent == agent:
		set_selected_agent(null)
	refresh_targets()
	agent_count_changed.emit(agents.size())

func select_nearest_agent(in_global_position: Vector2) -> void:
	var nearest: Botek
	var nearest_distance := 30.0
	for agent in agents:
		var distance := agent.global_position.distance_to(in_global_position)
		if distance < nearest_distance:
			nearest = agent
			nearest_distance = distance
	set_selected_agent(nearest)

func set_selected_agent(agent: Botek) -> void:
	if is_instance_valid(selected_agent):
		selected_agent.is_selected = false
		selected_agent.queue_redraw()
	selected_agent = agent if is_instance_valid(agent) else null
	if is_instance_valid(selected_agent):
		selected_agent.is_selected = true
		selected_agent.queue_redraw()
		if selected_only:
			selected_agent.behavior = current_behavior
	selected_agent_changed.emit(selected_agent)

func set_behavior(new_behavior: Botek.Behavior) -> void:
	if new_behavior < Botek.Behavior.SEEK or new_behavior > Botek.Behavior.EVADE:
		push_warning("Ignoring unknown steering behavior: %d" % new_behavior)
		return
		
	current_behavior = new_behavior
	if selected_only:
		if is_instance_valid(selected_agent):
			selected_agent.behavior = current_behavior
			selected_agent.set_predator(new_behavior == Botek.Behavior.PURSUIT)

	else:
		for agent in agents:
			agent.behavior = current_behavior
			agent.set_predator(new_behavior == Botek.Behavior.PURSUIT)


func set_selected_only(enabled: bool) -> void:
	selected_only = enabled
	if not selected_only:
		for agent in agents:
			agent.behavior = current_behavior

func set_collision_avoidance_enabled(enabled: bool) -> void:
	collision_avoidance_enabled = enabled
	for agent in agents:
		agent.collision_avoidance_enabled = enabled

func refresh_targets() -> void:
	var predator: Botek
	for agent in agents:
		if agent.is_predator and is_instance_valid(agent):
			predator = agent
			break

	for agent in agents:
		if agent.is_predator:
			agent.target_agent = nearest_agent_to(agent, false)
		elif is_instance_valid(predator) and predator != agent:
			agent.target_agent = predator
		else:
			agent.target_agent = nearest_agent_to(agent, true)

func nearest_agent_to(agent: Botek, include_predators: bool) -> Botek:
	var nearest: Botek
	var nearest_distance := INF
	for candidate in agents:
		if candidate == agent or not is_instance_valid(candidate):
			continue
		if not include_predators and candidate.is_predator:
			continue
		var distance := agent.global_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

func random_spawn_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var margin := 20.0
	return Vector2(
		randf_range(margin, maxf(viewport_size.x - margin, margin)),
		randf_range(margin, maxf(viewport_size.y - margin, margin))
	)
