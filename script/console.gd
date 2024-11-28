extends Window
class_name Console

func _ready() -> void:
	Static.console = self
	_connect_internals()

func print_console(text: String) -> void:
	$Panel/Output.text += text

func _connect_internals() -> void:
	$Panel/Input.gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ENTER and event.pressed == true:
			Commands.call_deferred($Panel/Input.text.split(" ")[0], $Panel/Input.text.split(" ").slice(1))
			$Panel/Input.text = ""
