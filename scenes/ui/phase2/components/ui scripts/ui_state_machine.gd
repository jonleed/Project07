class_name UI_State_Machine
extends Node

signal toggle_ui(visiblity: bool)
signal toggle_inputs(enabled: bool)

enum State { IDLE, ACTING, THINKING, HIDDEN }
##Idle
# When the GUI is on the screen in an active state
##Acting
# When an action is selected and the player must either cancel to go back to idle or select the targets to move to thinking
##Thinking
# When an action and target are decided and the appropriate channels are sent signals, we await a length of time then idle once more
##Hidden
# When the GUI is hidden and inactive 

var current_state: State = State.IDLE

func _ready():
	enter_state(State.HIDDEN)

func enter_state(new_state: State):
	exit_state(current_state)
	current_state = new_state
	match current_state:
		State.IDLE:
			_on_enter_idle()
		State.ACTING:
			_on_enter_acting()
		State.THINKING:
			_on_enter_thinking()
		State.HIDDEN:
			_on_enter_hidden()

func exit_state(old_state: State):
	match old_state:
		State.IDLE:
			_on_exit_idle()
		State.ACTING:
			_on_exit_acting()
		State.THINKING:
			_on_exit_thinking()
		State.HIDDEN:
			_on_exit_hidden()

## State Logic

# IDLE
func _on_enter_idle():
	show_ui(true)
	enable_inputs(true)

func _on_exit_idle():
	pass

# SELECTING
func _on_enter_acting():
	show_ui(true)
	enable_inputs(true)
	highlight_actions()

func _on_exit_acting():
	clear_highlights()

# THINKING
func _on_enter_thinking():
	enable_inputs(false)
	start_wait_period()

func _on_exit_thinking():
	stop_wait_period()

# HIDDEN
func _on_enter_hidden():
	show_ui(false)
	enable_inputs(false)

func _on_exit_hidden():
	pass

# --- Helper functions ---

func show_ui(visiblity: bool):
	emit_signal("toggle_ui", visiblity)
	pass

func enable_inputs(enabled: bool):
	emit_signal("toggle_inputs", enabled)
	pass

func highlight_actions():
	pass

func clear_highlights():
	pass

func start_wait_period():
	# emit signals, handle delays, etc.
	await get_tree().create_timer(1.0).timeout
	enter_state(State.IDLE)

func stop_wait_period():
	pass

# --- External triggers ---

func select_action():
	if current_state == State.IDLE:
		enter_state(State.ACTING)

func confirm_selection():
	if current_state == State.ACTING:
		enter_state(State.ACTING)

func cancel_selection():
	if current_state == State.ACTING:
		enter_state(State.IDLE)
