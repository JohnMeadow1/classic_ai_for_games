extends AgentBehavior

func calculate_steering(agent:Botek, delta: float) -> Vector2:
	if is_instance_valid(agent.target_agent) and agent.target_agent != agent:
		var target := predict_position(agent, agent.target_agent.position, agent.target_agent.velocity)
		return seek(agent, target)
	return agent.calculate_wander(delta)
