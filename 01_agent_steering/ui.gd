extends CanvasLayer

func _ready():
	randomize()
	Globals.alignment_rate  = %alignment.value
	Globals.cohesion_rate   = %cohesion.value
	Globals.separation_rate = %separation.value
	
	Globals.friction         = %friction.value
	Globals.view_range       = %view_range.value 
	Globals.view_range_squared = Globals.view_range * Globals.view_range
	Globals.view_range_fov    = deg_to_rad( %range_fov.value * 0.5 )
	
	Globals.separation_range = %separation_range.value
	Globals.separation_range_squared = Globals.separation_range * Globals.separation_range
	Globals.separation_range_fov    = deg_to_rad( %separation_fov.value * 0.5 )
	
	Globals.max_speed        = %max_speed.value

func _on_alignment_value_changed(value):
	Globals.alignment_rate = value

func _on_cohesion_value_changed(value):
	Globals.cohesion_rate = value

func _on_separation_value_changed(value):
	Globals.separation_rate = value

func _on_friction_value_changed(value):
	Globals.friction = value

func _on_view_range_value_changed(value):
	Globals.view_range = value
	Globals.view_range_squared = value * value
	
func _on_separation_range_value_changed(value):
	Globals.separation_range = value
	Globals.separation_range_squared = value * value

func _on_range_fov_value_changed(value):
	Globals.view_range_fov = deg_to_rad(value * 0.5)

func _on_separation_fov_value_changed(value):
	Globals.separation_range_fov = deg_to_rad(value * 0.5)

func _on_max_speed_value_changed(value):
	Globals.max_speed = value

func _on_min_speed_value_changed(value):
	Globals.min_speed = value

func _on_space_wrap_toggled(button_pressed):
	Globals.space_wrap = button_pressed


func _on_hide_ui_toggled(toggled_on: bool) -> void:
	%HBox.visible = toggled_on

func update_count(in_value):
	%count.text = str(in_value)
