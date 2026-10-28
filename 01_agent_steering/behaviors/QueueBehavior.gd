extends AgentBehavior



func calculate_steering(agent:Botek, _delta: float) -> Vector2:
	if agent.get_neighbor_ahead() == null:
		return Vector2.ZERO

	var braking_force := -agent.velocity * Steering.queue_brake_strength
	var force := agent.steering + braking_force + agent.separation()
	agent.desired_velocity = agent.velocity + force
	return force

#func queue(in_steering:Vector2) -> Vector2:
#	if get_neighbor_ahead() == null:
#		return in_steering
#
#	var braking_force := -velocity * queue_brake_strength
#	var force := in_steering + braking_force + separation()
#	desired_velocity = velocity + force
#	return force
