extends AgentBehavior

func calculate_steering(agent:Botek,delta: float) -> Vector2:
	if is_instance_valid(agent.target_agent) and agent.target_agent != agent:
		var l_distance := agent.position.distance_to(agent.target_agent.position)
		if l_distance <= Steering.view_range:
			var target := predict_position(agent, agent.target_agent.position, agent.target_agent.velocity)
			if is_timer_ready and l_distance <= Steering.view_range * 0.5:
				_drop_opstacle(agent)
				
			return flee(agent, target)
		
	return agent.calculate_wander(delta)



func _drop_opstacle(agent:Botek) -> void:
	is_timer_ready = false
	agent.start_timer()
	var new_obstacle = preload("res://obstacle_temporary.tscn").instantiate()
	Steering.obstacle_node.add_child(new_obstacle)
	new_obstacle.position = agent.position
	
