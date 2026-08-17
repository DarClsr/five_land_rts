extends Node
"""启动时注册输入动作（M0 用代码注册，M3 迁入项目设置）。"""

func _ready() -> void:
	_add_key_action("pan_left", [KEY_A, KEY_LEFT])
	_add_key_action("pan_right", [KEY_D, KEY_RIGHT])
	_add_key_action("pan_up", [KEY_W, KEY_UP])
	_add_key_action("pan_down", [KEY_S, KEY_DOWN])
	_add_mouse_action("zoom_in", MOUSE_BUTTON_WHEEL_UP)
	_add_mouse_action("zoom_out", MOUSE_BUTTON_WHEEL_DOWN)
	_add_mouse_action("select", MOUSE_BUTTON_LEFT)
	_add_mouse_action("command", MOUSE_BUTTON_RIGHT)

func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)

func _add_mouse_action(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
