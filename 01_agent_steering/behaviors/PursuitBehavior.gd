extends AgentBehavior

func calculate_steering(agent:Botek, delta: float) -> Vector2:
	if is_instance_valid(agent.target_agent) and agent.target_agent != agent:
		var target := predict_position(agent, agent.target_agent.position, agent.target_agent.velocity)
		agent.position += agent.velocity * 0.1 * delta
		if agent.position.distance_to(agent.target_agent.position) < 20.0:
			agent.target_agent.queue_free()
			
		var l_distance := agent.position.distance_to(agent.target_agent.position)
		if is_timer_ready and l_distance <= Steering.view_range * 0.6:
			do_attack(agent, 70.0)

			
		
		return seek(agent, target)
	return agent.calculate_wander(delta)

func do_attack(agent:Botek, in_attack_range:float):
	agent.start_timer()
	is_timer_ready = false
	agent.position += agent.velocity.normalized() * in_attack_range
