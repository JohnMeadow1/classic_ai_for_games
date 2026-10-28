extends AgentBehavior

func calculate_steering(agent:Botek, _delta: float) -> Vector2:
	var target := agent.destination if agent.has_destination else agent.get_global_mouse_position()
	return seek(agent,target)
