class_name DragManager extends Node2D

## Drag, drop and rotate for ingredient pieces.
## Adapted from Waste Crusher's drag_manager.gd.

signal piece_placed(piece: IngredientPiece)
signal piece_returned(piece: IngredientPiece)

var tray: IngredientTray
var kuali: KualiGrid

var _dragged: IngredientPiece = null
var _offset: Vector2 = Vector2.ZERO
var _enabled: bool = true


func set_enabled(v: bool) -> void:
	_enabled = v
	if not v and _dragged:
		_return_to_tray(_dragged)
		_dragged = null
		kuali.clear_hover()


func is_dragging() -> bool:
	return _dragged != null


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pick(get_global_mouse_position())
			else:
				_drop()
		elif _dragged and mb.pressed and mb.button_index in [
				MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_rotate()
			get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed and not event.echo:
		if _dragged and (event as InputEventKey).keycode == KEY_R:
			_rotate()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _dragged:
		_dragged.global_position = get_global_mouse_position() - _offset
		kuali.update_hover(_dragged)


func _piece_at(pos: Vector2) -> IngredientPiece:
	if tray:
		var p := tray.piece_at(pos)
		if p:
			return p

	if kuali:
		for id in kuali.pieces:
			var piece: IngredientPiece = kuali.pieces[id]
			for c in piece.cells:
				var r := Rect2(piece.global_position + Vector2(c) * IngredientPiece.CELL,
					Vector2.ONE * IngredientPiece.CELL)
				if r.has_point(pos):
					return piece
	return null


func _pick(pos: Vector2) -> void:
	var picked := _piece_at(pos)
	if not picked:
		return

	if picked.state == IngredientPiece.State.IN_KUALI:
		kuali.remove(picked)

	_dragged = picked
	picked.state = IngredientPiece.State.DRAGGING
	_offset = picked.pixel_size() * 0.5

	if picked.get_parent() != self:
		if picked.get_parent():
			picked.get_parent().remove_child(picked)
		add_child(picked)

	picked.global_position = pos - _offset
	picked.z_index = 100
	picked.set_lifted(true)

	kuali.update_hover(picked)
	get_viewport().set_input_as_handled()


func _drop() -> void:
	if not _dragged:
		return

	var piece := _dragged
	_dragged = null
	piece.set_lifted(false)
	piece.z_index = 0

	var desired := kuali.cell_at(piece.global_position)
	var snapped := kuali.best_fit(piece, desired)

	if snapped != KualiGrid.INVALID:
		kuali.place(piece, snapped)
		piece_placed.emit(piece)
	elif kuali.can_place(piece, desired):
		kuali.place(piece, desired)
		piece_placed.emit(piece)
	else:
		_return_to_tray(piece)

	kuali.clear_hover()
	get_viewport().set_input_as_handled()


func _rotate() -> void:
	var before := _dragged.pixel_size()
	_dragged.rotate_cw()
	# Keep the piece centred on the cursor as its bounds change.
	_dragged.global_position += (before - _dragged.pixel_size()) * 0.5
	_offset = _dragged.pixel_size() * 0.5
	kuali.update_hover(_dragged)


func _return_to_tray(piece: IngredientPiece) -> void:
	tray.return_piece(piece)
	piece_returned.emit(piece)
