extends AgentBehavior

func calculate_steering(agent:Botek,_delta: float) -> Vector2:
	#var target := 
	var steering := Steering.map.get_direction_vector(agent.position) *100.00
	#if agent.position.distance_to(target) < Steering.arrival_distance:
	#	agent.request_behavior("WANDER")
	return steering
