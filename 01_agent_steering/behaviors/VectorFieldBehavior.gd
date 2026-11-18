extends AgentBehavior

func calculate_steering(agent:Botek,_delta: float) -> Vector2:
	#var steering := Steering.map.get_direction_vector(agent.position) * 100.00
	var steering := Steering.map.get_flow_field_vector(agent.position) * 100.00
	return steering
