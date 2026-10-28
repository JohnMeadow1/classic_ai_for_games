extends AgentBehavior

func calculate_steering(agent:Botek,_delta: float) -> Vector2:
	return flee(agent, agent.get_global_mouse_position())
