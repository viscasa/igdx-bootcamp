extends Node

## Keeps cursor feedback consistent for UI buttons and world-space interactions.
## BaseButton nodes are configured automatically, including runtime instances.

var _pointing_claims: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_configure_node)
	_configure_branch(get_tree().root)


func _process(_delta: float) -> void:
	var pointing := false
	for id in _pointing_claims.keys():
		var reference := _pointing_claims[id] as WeakRef
		if reference.get_ref() == null:
			_pointing_claims.erase(id)
		else:
			pointing = true
	Input.set_default_cursor_shape(
		Input.CURSOR_POINTING_HAND if pointing else Input.CURSOR_ARROW)


func set_pointing(source: Object, active: bool) -> void:
	if source == null:
		return
	var id := source.get_instance_id()
	if active:
		_pointing_claims[id] = weakref(source)
	else:
		_pointing_claims.erase(id)


func _configure_branch(node: Node) -> void:
	_configure_node(node)
	for child in node.get_children():
		_configure_branch(child)


func _configure_node(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
