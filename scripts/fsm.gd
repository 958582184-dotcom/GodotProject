extends Node

class_name FSM

signal on_state_transitioned(state_name: String )

@export var initial_state: NodePath

var curr_state: State


func _ready() -> void:
	await  owner.ready
	for state: State in get_children():
		state.fsm = self
	
	curr_state = get_node(initial_state)
	curr_state.enter_state()


func transition_to(state_name: String) -> void:
	if not has_node(state_name):
		return
	curr_state.exit_state()
	curr_state = get_node(state_name)
	curr_state.enter_state()
	on_state_transitioned.emit(state_name)
