extends AgentBehavior

func calculate_steering(agent:Botek,_delta: float) -> Vector2:
	var target := agent.destination if agent.has_destination else agent.get_global_mouse_position()
	var steering := arrival(agent,target)
	if agent.position.distance_to(target) < Steering.arrival_distance:
		agent.request_behavior("WANDER")
	return steering
