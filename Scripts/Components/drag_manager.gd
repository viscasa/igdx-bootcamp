class_name DragManager extends Node2D

## Drag and drop inside the kitchen:
##   - ingredients: tray -> kuali, or tray -> a tool station
##   - potions:     bench -> panci
##
## Handing a jamu to a person happens at the counter (kasir.gd), not here —
## the two rooms are separate scenes and the kitchen has no queue.

signal ingredient_placed(piece: IngredientPiece)
signal potion_dropped_outside(potion: Potion)
## A piece was dropped into a machine; the room decides what to do with the
## shapes that come out.
signal piece_dropped_on_station(piece: IngredientPiece, station: ToolStation)

var tray: IngredientTray
var kuali: KualiGrid
var panci: Panci
## Machines on the bench. Dropping a piece into one runs it.
var stations: Array[ToolStation] = []

var _piece: IngredientPiece = null
var _potion: Potion = null
var _offset: Vector2 = Vector2.ZERO
var _enabled: bool = true


func set_enabled(v: bool) -> void:
	_enabled = v
	if not v:
		if _piece:
			_return_piece(_piece)
			_piece = null
			kuali.clear_hover()
			_clear_station_hover()
		if _potion:
			_return_potion(_potion)
			_potion = null
			_clear_targets()


func is_dragging() -> bool:
	return _piece != null or _potion != null


func carrying_potion() -> bool:
	return _potion != null


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
		elif _piece and mb.pressed and mb.button_index in [
				MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_rotate()
			get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed and not event.echo:
		if _piece and (event as InputEventKey).keycode == KEY_R:
			_rotate()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		var mouse := get_global_mouse_position()
		if _piece:
			_piece.global_position = mouse - _offset
			var over := _station_at(mouse)
			for s in stations:
				s.set_hover(s == over)
			# Hide the pot ghost while aiming at a machine, so only one
			# target ever looks armed.
			if over:
				kuali.clear_hover()
			else:
				kuali.update_hover(_piece)
		elif _potion:
			_potion.global_position = mouse - _offset
			_update_targets(mouse)


# ═══════════════ PICK ═══════════════

func _pick(pos: Vector2) -> void:
	# Potions take priority — they sit on top of everything.
	var potion := _potion_at(pos)
	if potion:
		_pick_potion(potion, pos)
		return

	var piece := _piece_at(pos)
	if piece:
		_pick_piece(piece, pos)


func _potion_at(pos: Vector2) -> Potion:
	if panci:
		var p := panci.potion_at(pos)
		if p:
			return p
	# A finished potion waiting beside the kuali.
	for child in get_parent().get_children():
		if child is Potion and (child as Potion).hits(pos):
			return child
	return null


func _pick_potion(potion: Potion, pos: Vector2) -> void:
	if panci:
		var slot := panci.slot_of(potion)
		if slot >= 0:
			panci.take(slot)

	_potion = potion
	_offset = Vector2(0, -Potion.H * 0.5)

	_reparent(potion, self)
	potion.global_position = pos - _offset
	potion.z_index = 200
	potion.set_lifted(true)

	_update_targets(pos)
	get_viewport().set_input_as_handled()


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


func _pick_piece(piece: IngredientPiece, pos: Vector2) -> void:
	if piece.state == IngredientPiece.State.IN_KUALI:
		kuali.remove(piece)

	_piece = piece
	piece.state = IngredientPiece.State.DRAGGING
	_offset = piece.pixel_size() * 0.5

	_reparent(piece, self)
	piece.global_position = pos - _offset
	piece.z_index = 100
	piece.set_lifted(true)

	kuali.update_hover(piece)
	get_viewport().set_input_as_handled()


# ═══════════════ DROP ═══════════════

func _drop() -> void:
	if _potion:
		_drop_potion()
	elif _piece:
		_drop_piece()


func _drop_potion() -> void:
	var potion := _potion
	_potion = null
	potion.set_lifted(false)
	potion.z_index = 0

	var mouse := get_global_mouse_position()

	# The pot? Simmer it.
	if panci:
		var pslot := panci.slot_at(mouse)
		if pslot >= 0 and panci.put(potion, pslot):
			_clear_targets()
			get_viewport().set_input_as_handled()
			return

	# Nowhere useful — park it back on the bench.
	_return_potion(potion)
	_clear_targets()
	get_viewport().set_input_as_handled()


func _drop_piece() -> void:
	var piece := _piece
	_piece = null
	piece.set_lifted(false)
	piece.z_index = 0

	# A machine gets first refusal: its mouth sits off the pot, so there is
	# no ambiguity about which target the player meant.
	var station := _station_at(get_global_mouse_position())
	if station:
		kuali.clear_hover()
		_clear_station_hover()
		piece_dropped_on_station.emit(piece, station)
		get_viewport().set_input_as_handled()
		return

	var desired := kuali.cell_at(piece.global_position)
	var snapped := kuali.best_fit(piece, desired)

	if snapped != KualiGrid.INVALID:
		kuali.place(piece, snapped)
		ingredient_placed.emit(piece)
	elif kuali.can_place(piece, desired):
		kuali.place(piece, desired)
		ingredient_placed.emit(piece)
	else:
		_return_piece(piece)

	kuali.clear_hover()
	_clear_station_hover()
	get_viewport().set_input_as_handled()


func _station_at(pos: Vector2) -> ToolStation:
	for s in stations:
		if s.accepts_at(pos):
			return s
	return null


func _clear_station_hover() -> void:
	for s in stations:
		s.set_hover(false)


func _return_potion(potion: Potion) -> void:
	# Prefer the pot; otherwise leave it on the counter.
	if panci and panci.has_space() and panci.put_anywhere(potion):
		return
	potion_dropped_outside.emit(potion)


func _return_piece(piece: IngredientPiece) -> void:
	tray.return_piece(piece)


func _rotate() -> void:
	var before := _piece.pixel_size()
	_piece.rotate_cw()
	_piece.global_position += (before - _piece.pixel_size()) * 0.5
	_offset = _piece.pixel_size() * 0.5
	kuali.update_hover(_piece)


# ═══════════════ DROP TARGETS ═══════════════

func _update_targets(mouse: Vector2) -> void:
	if panci:
		var s := panci.slot_at(mouse)
		panci.set_hover(s if s >= 0 and panci.potions[s] == null else -1)


func _clear_targets() -> void:
	if panci:
		panci.clear_hover()


func _reparent(node: Node, new_parent: Node) -> void:
	if node.get_parent() == new_parent:
		return
	if node.get_parent():
		node.get_parent().remove_child(node)
	new_parent.add_child(node)
