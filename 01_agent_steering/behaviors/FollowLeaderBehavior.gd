extends AgentBehavior

func calculate_steering(agent:Botek,_delta: float) -> Vector2:
	if not is_instance_valid(agent.target_agent) or agent.target_agent == agent:
		return Vector2.ZERO

	var leader = agent.target_agent
	var leader_facing: Vector2 = leader.velocity.normalized()
	if leader_facing == Vector2.ZERO:
		leader_facing = Vector2.RIGHT.rotated(leader.angle)

	var leader_offset := leader_facing * Steering.leader_behind_distance
	var behind_leader: Vector2 = leader.position - leader_offset
	var ahead_of_leader: Vector2 = leader.position + leader_offset

	var force := Vector2.ZERO
	if agent.position.distance_to(ahead_of_leader) <= Steering.leader_sight_radius:
		var predicted_leader := predict_position(agent, leader.position, leader.velocity)
		force += flee(agent, predicted_leader)
	force += arrival(agent, behind_leader)
	force += agent.separation()

	agent.desired_velocity = agent.velocity + force
	return force
