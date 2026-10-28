extends AgentBehavior

func calculate_steering(agent:Botek, _delta: float) -> Vector2:
	if agent.path.is_empty():
		return Vector2.ZERO

	agent.path_index = clampi(agent.path_index, 0, agent.path.size() - 1)
	var is_last_waypoint := agent.path_index == agent.path.size() - 1
	if agent.position.distance_to(agent.path[agent.path_index]) <= Steering.path_arrive_radius:
		if not is_last_waypoint:
			agent.path_index += 1
		is_last_waypoint = agent.path_index == agent.path.size() - 1

	if is_last_waypoint:
		var destination: Vector2 = agent.path[agent.path_index]
		if agent.position.distance_to(destination) <= Steering.arrival_distance:
			agent.path_index = 0
			agent.path.clear()
			agent.request_behavior("WANDER")
		return arrival(agent, destination)
	return seek(agent, agent.path[agent.path_index])
