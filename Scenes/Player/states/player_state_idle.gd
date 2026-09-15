extends PlayerState
class_name PlayerStateIdle

func enter_state() -> void:
	player.play_direction_anim("idle")
	pass
func exit_state()-> void:
	pass
func process_state( delta: float)->void:
	pass

func _input(event: InputEvent)-> void:
	if event.is_action_pressed("attack"):
		fsm.transition_to("Attack")
		return
	
	if player.is_moving():
		fsm.transition_to("Walk")
