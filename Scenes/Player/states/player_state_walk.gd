extends PlayerState
class_name PlayerStateWalk

func enter_state() -> void:
	player.play_direction_anim("walk")
	pass
func exit_state()-> void:
	pass
func process_state( delta: float)->void:
	var input_vector = Input.get_vector("move_left","move_right","move_up","move_down")
	
	if Input.is_action_just_pressed("attack"):
		fsm.transition_to("Attack")
		return

	
	if input_vector == Vector2.ZERO:
		fsm.transition_to("Idle")
		return
	player.update_direction(input_vector)
	player.play_direction_anim("walk")
	
	player.velocity = input_vector*player.move_speed
	player.move_and_slide()
	pass
