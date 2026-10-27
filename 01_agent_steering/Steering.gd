extends Node


@export_group("Behavior tuning")
var max_steering_force     := 300.0
var wander_distance        := 60.0
var wander_radius          := 30.0
var wander_jitter          := TAU #6.283 

var max_see_ahead          := 60.0
var max_avoid_force        := 150.0
var path_arrive_radius     := 20.0

var leader_behind_distance := 40.0
var leader_sight_radius    := 50.0

var obstacle_distance := 100.0

var queue_ahead_distance   := 25.0
var queue_radius           := 25.0
var queue_brake_strength   := 0.8

var alignment_rate     := 10.0
var cohesion_rate      := 10.0
var separation_rate    := 15.0

var friction           := 0.0

var view_range         := 0.0
var view_range_fov     := 0.0

var max_speed          := 0.0

var separation_range := 0.0
var separation_range_fov     := 0.0

var debug_draw := true
var space_wrap := false

var obstacle_node :Node2D
