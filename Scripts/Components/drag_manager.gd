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
			_aim_at_stations()
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
	# Cut halves resting on a machine come first — they sit on top of the
	# bench and are the thing the player is reaching for after a cut.
	for s in stations:
		var cut := s.piece_at(pos)
		if cut:
			return cut

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

	# Lifting a half off the machine frees it to take the next ingredient.
	for s in stations:
		if s.owns(piece):
			s.release(piece)
			# A cut half is a real piece now; give it an id so the pot can
			# track it like anything else.
			if piece.piece_id < 0:
				piece.piece_id = kuali.next_id()
			break

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

	# A machine gets first refusal. The pot only sees the piece if it was
	# not released over a machine, so the two targets never compete.
	#
	# Both the hit test and the column come from the intended position for
	# the same reason as the hover: the piece is already sitting snapped,
	# so reading it back would always give the column it snapped to.
	var intended := get_global_mouse_position() - _offset
	var station := _station_at(intended)
	if station:
		station.set_pending_col(station.cut_col_for(piece.cells, intended))
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


## Snap the dragged piece onto whichever machine it overlaps, and show the
## seam the blade would open.
##
## The snap is the mechanic, not polish: the piece jumps so the blade sits
## exactly on a column boundary, which is how the player sees where the cut
## will land before letting go. Waste Crusher does the same thing.
##
## Aim is taken from the INTENDED position (mouse minus grab offset), never
## from where the piece currently sits. Reading the snapped position back
## would feed the snap into itself: the piece lands exactly on a column
## boundary, that boundary resolves to the same column next frame, and the
## aim freezes on whichever column it first touched.
func _aim_at_stations() -> void:
	var piece := _piece
	if piece == null:
		return

	var intended := get_global_mouse_position() - _offset
	var over := _station_at(intended)

	for s in stations:
		if s != over:
			s.hide_preview()

	if over == null:
		piece.global_position = intended
		kuali.update_hover(piece)
		return

	var col: int = over.cut_col_for(piece.cells, intended)
	over.set_pending_col(col)
	piece.global_position = over.snap_position(piece.cells, intended)
	over.show_preview(piece)

	# Only one target may look armed at a time.
	kuali.clear_hover()


func _station_at(piece_pos: Vector2) -> ToolStation:
	if _piece == null:
		return null
	for s in stations:
		if s.overlaps(piece_pos, _piece.cells):
			return s
	return null


func _clear_station_hover() -> void:
	for s in stations:
		s.hide_preview()


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
