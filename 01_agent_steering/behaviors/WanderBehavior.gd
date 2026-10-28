extends AgentBehavior

var wander_angle := 0.0

func calculate_steering(agent:Botek,delta: float) -> Vector2:
	wander_angle += randf_range(-Steering.wander_jitter, Steering.wander_jitter) * delta
	agent.circle_center = agent.facing * Steering.wander_distance
	agent.circle_displacement = Vector2.RIGHT.rotated(wander_angle) * Steering.wander_radius
	return agent.steer_toward(agent.circle_center + agent.circle_displacement)
