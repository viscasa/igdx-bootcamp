class_name KualiGrid extends Node2D

## The pot. Holds an irregular grid of cells; the player fills every one.
## Adapted from Waste Crusher's landfill_grid.gd — the key change is that
## completion is graded (BrewResult), not a win/lose boolean.

signal changed
signal filled
## The player pressed SELESAI: turn whatever is in here into a jamu.
signal brew_requested

const CELL := IngredientPiece.CELL
const INVALID := Vector2i(2147483647, 2147483647)

const BTN_W := 132
const BTN_H := 52
const BTN_GAP := 16
const EMPTY_SIZE := Vector2(310, 230)
const STATUS_W := 210
const STATUS_H := 74
const BODY_FONT := preload("res://Assets/Fonts/kelmscottroman/KelmscottRomanNF.ttf")

## How far (in cells) placement will magnet-snap to a valid spot.
@export var snap_radius: float = 1.4

var grid: Dictionary = {}          ## Vector2i -> piece_id (0 = empty)
var pieces: Dictionary = {}        ## piece_id -> IngredientPiece
var residue: Dictionary = {}       ## Vector2i -> true (blocked by leftovers)

## Set by the kitchen: false when the panci has no free slot, so the button
## can say why it will not fire.
var panci_has_room: bool = true

var _hover_cells: Array[Vector2i] = []
var _hover_valid: bool = false
var _next_id: int = 1
var _hover_btn: bool = false


func _ready() -> void:
	var action := get_node_or_null("ActionButton") as Button
	if action and not action.pressed.is_connected(_on_action_pressed):
		action.set_meta("sfx_pressed", &"")
		action.pressed.connect(_on_action_pressed)
	set_process(true)
	_sync_visuals()


func _process(_delta: float) -> void:
	_sync_visuals()


func _on_action_pressed() -> void:
	brew_requested.emit()


## `shape` lists every cell that is inside the pot.
func build(shape: Array[Vector2i], residue_cells: Array[Vector2i] = []) -> void:
	grid.clear()
	pieces.clear()
	residue.clear()
	_next_id = 1

	for c in shape:
		grid[c] = 0

	for c in residue_cells:
		if grid.has(c):
			grid[c] = -1        # -1 marks residue: occupied, not a piece
			residue[c] = true

	_hover_cells.clear()
	queue_redraw()
	changed.emit()


func next_id() -> int:
	var id := _next_id
	_next_id += 1
	return id


# ═══════════════ SELESAI BUTTON ═══════════════

## SELESAI sits beside the kuali, because this is where mixing ends. The
## player's attention is already on the pot they just filled; putting the
## finish button anywhere else asks them to look away to commit.
##
## Placed off the right edge of the actual grid rather than at a fixed
## offset, so it follows the pot when a different silhouette is dealt.
func button_rect() -> Rect2:
	if grid.is_empty():
		return Rect2(Vector2((EMPTY_SIZE.x - BTN_W) * 0.5,
			EMPTY_SIZE.y - BTN_H - 20.0), Vector2(BTN_W, BTN_H))

	var b := GridLogic.bounds(grid)
	var x := (b.position.x + b.size.x) * CELL + BTN_GAP
	var y := b.position.y * CELL + (b.size.y * CELL - BTN_H) * 0.5
	return Rect2(Vector2(x, y), Vector2(BTN_W, BTN_H))


func button_has_point(global_pos: Vector2) -> bool:
	return button_rect().has_point(to_local(global_pos))


func has_contents() -> bool:
	return not pieces.is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var over := button_has_point(get_global_mouse_position())
		if over != _hover_btn:
			_hover_btn = over
			queue_redraw()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT \
				and button_has_point(get_global_mouse_position()):
			brew_requested.emit()
			get_viewport().set_input_as_handled()


## Like the AMBIL button at the counter, this one keeps its outline: a
## button has to look pressable, and this is the step that turns a pile of
## ingredients into a jamu.
func _draw_button() -> void:
	var font: Font = BODY_FONT
	var r := button_rect()
	var filled_ := has_contents()
	var live := filled_ and panci_has_room

	var col := Color("542512")
	var sub_col := Color("654431")
	var label := "SELESAI"
	var sub := "jadikan jamu"

	if grid.is_empty():
		label = "AMBIL DULU"
		sub = "pilih orang di kasir"
		col = Color("ead4a3")
		sub_col = Color("d4bd91")
	elif not filled_:
		label = "KUALI KOSONG"
		sub = "isi bahan dulu"
	elif not panci_has_room:
		label = "PANCI PENUH"
		sub = "ambil yang matang"
		col = Color("9b3329")
	else:
		col = Color("6fd48f") if _hover_btn else Color("ffd36f")

	draw_rect(r, Color(col, 0.18) if (_hover_btn and live) else Color(0, 0, 0, 0))
	draw_rect(r, col, false, 2.0 if live else 1.0)

	draw_string(font, Vector2(r.position.x, r.position.y + 22), label,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, col)
	draw_string(font, Vector2(r.position.x, r.position.y + 38), sub,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, sub_col)


func _bounds_rect() -> Rect2:
	if grid.is_empty():
		return Rect2(Vector2.ZERO, EMPTY_SIZE)
	var b := GridLogic.bounds(grid)
	return Rect2(Vector2(b.position) * CELL,
		Vector2(b.size) * CELL)


func cell_at(global_pos: Vector2) -> Vector2i:
	var local := global_pos - global_position
	return Vector2i(floori(local.x / CELL + 0.5), floori(local.y / CELL + 0.5))


func can_place(piece: IngredientPiece, gpos: Vector2i) -> bool:
	return GridLogic.can_place(grid, piece.cells, gpos.x, gpos.y)


## Nearest valid placement to `desired`, or INVALID if none is close enough.
func best_fit(piece: IngredientPiece, desired: Vector2i) -> Vector2i:
	if grid.is_empty():
		return INVALID

	var b := GridLogic.bounds(grid)
	var shape := GridLogic.shape_size(piece.cells)

	var best := INVALID
	var best_dist := INF

	for gx in range(b.position.x - shape.x, b.end.x + 1):
		for gy in range(b.position.y - shape.y, b.end.y + 1):
			var gp := Vector2i(gx, gy)
			if not can_place(piece, gp):
				continue
			var d := Vector2(gp - desired).length_squared()
			if d < best_dist:
				best_dist = d
				best = gp

	if best != INVALID and best_dist > snap_radius * snap_radius:
		return INVALID
	return best


## Any legal spot, ignoring distance. Used by the tools, which must land a
## reshaped piece somewhere rather than drop it on the floor.
func first_fit(piece: IngredientPiece) -> Vector2i:
	if grid.is_empty():
		return INVALID

	var b := GridLogic.bounds(grid)
	var shape := GridLogic.shape_size(piece.cells)

	for gy in range(b.position.y - shape.y, b.end.y + 1):
		for gx in range(b.position.x - shape.x, b.end.x + 1):
			var gp := Vector2i(gx, gy)
			if can_place(piece, gp):
				return gp
	return INVALID


func place(piece: IngredientPiece, gpos: Vector2i) -> void:
	GridLogic.place(grid, piece.cells, gpos.x, gpos.y, piece.piece_id)
	pieces[piece.piece_id] = piece
	piece.state = IngredientPiece.State.IN_KUALI
	piece.grid_pos = gpos

	if piece.get_parent() != self:
		if piece.get_parent():
			piece.get_parent().remove_child(piece)
		add_child(piece)

	piece.position = Vector2(gpos) * CELL
	piece.z_index = 0

	queue_redraw()
	changed.emit()
	if is_full():
		filled.emit()


func remove(piece: IngredientPiece) -> void:
	GridLogic.remove(grid, piece.piece_id)
	pieces.erase(piece.piece_id)
	piece.grid_pos = Vector2i(-1, -1)
	queue_redraw()
	changed.emit()


func is_full() -> bool:
	return GridLogic.is_full(grid)


func empty_count() -> int:
	return GridLogic.count_empty(grid)


func placed_ingredients() -> Array[IngredientData]:
	var out: Array[IngredientData] = []
	for id in pieces:
		out.append(pieces[id].data)
	return out


## Parallel to placed_ingredients(): the real cell count of each piece,
## which differs from the pristine shape once a piece has been cut.
func placed_cell_counts() -> Array[int]:
	var out: Array[int] = []
	for id in pieces:
		out.append((pieces[id] as IngredientPiece).potency())
	return out


func filled_count() -> int:
	return grid.size() - empty_count()


## Cells the player can still reach — residue is walled off permanently.
func usable_count() -> int:
	return grid.size() - residue.size()


func current_dose() -> int:
	var total := 0
	for id in pieces:
		total += (pieces[id] as IngredientPiece).potency()
	return total


func current_cost() -> int:
	var total := 0
	for id in pieces:
		var p: IngredientPiece = pieces[id]
		total += p.data.cost_for_cells(p.potency())
	return total


func current_bitterness() -> int:
	var total := 0
	for id in pieces:
		total += (pieces[id] as IngredientPiece).data.bitterness
	return total


func current_sweetness() -> int:
	var total := 0
	for id in pieces:
		var ing := (pieces[id] as IngredientPiece).data
		total += ing.sweetness
		if ing.ingredient_id == &"gula_jawa":
			total += 4
		elif ing.ingredient_id == &"asam_jawa":
			total += 1
	return total


func current_taste_label() -> String:
	if pieces.is_empty():
		return "-"
	var net := maxi(current_bitterness() - current_sweetness(), 0)
	if net <= 0:
		return "seimbang"
	if net <= 2:
		return "agak pahit"
	if net <= 5:
		return "pahit"
	return "sangat pahit"


func current_heat_label() -> String:
	if pieces.is_empty():
		return "-"
	var ings := placed_ingredients()
	if ings.is_empty():
		return "-"
	var w := RecipeEvaluator.heat_window(ings)
	var c := (w.x + w.y) * 0.5
	if c < 0.45:
		return "api kecil"
	if c < 0.7:
		return "api sedang"
	return "api besar"


func clear_pieces() -> void:
	for id in pieces.keys():
		var p: IngredientPiece = pieces[id]
		if is_instance_valid(p):
			p.queue_free()
	pieces.clear()
	for c in grid:
		if not residue.has(c):
			grid[c] = 0
	queue_redraw()
	changed.emit()


# ───── Hover preview ─────

func update_hover(piece: IngredientPiece) -> void:
	var desired := cell_at(piece.global_position)
	var snapped := best_fit(piece, desired)

	var target := snapped if snapped != INVALID else desired
	_hover_valid = snapped != INVALID or can_place(piece, desired)

	_hover_cells.clear()
	for c in piece.cells:
		_hover_cells.append(target + c)
	queue_redraw()


func clear_hover() -> void:
	_hover_cells.clear()
	queue_redraw()


func _draw() -> void:
	# All visible kuali parts are real nodes in kuali_grid.tscn. Keeping the
	# gameplay component as a Node2D preserves the existing drag math while
	# scene-authored cells, panels and controls provide the presentation.
	return


func _sync_visuals() -> void:
	if not is_inside_tree():
		return
	var pot := get_node_or_null("PotBackground") as Control
	var cells_root := get_node_or_null("Cells")
	var empty := get_node_or_null("EmptyState") as Control
	var status := get_node_or_null("StatusPanel") as Control
	var action := get_node_or_null("ActionButton") as Button
	if pot == null or cells_root == null or empty == null or status == null or action == null:
		return

	var is_open := not grid.is_empty()
	empty.visible = not is_open
	pot.visible = is_open
	cells_root.visible = is_open
	status.visible = is_open

	if is_open:
		var bounds := _bounds_rect()
		pot.position = bounds.position - Vector2(18, 18)
		pot.size = bounds.size + Vector2(36, 36)
		status.position = Vector2(pot.position.x, pot.position.y + pot.size.y + 8.0)
		var keys := grid.keys()
		for i in range(cells_root.get_child_count()):
			var cell_node := cells_root.get_child(i) as KualiCell
			cell_node.visible = i < keys.size()
			if i >= keys.size():
				continue
			var coord: Vector2i = keys[i]
			cell_node.position = Vector2(coord) * CELL
			var hover_color := Color.TRANSPARENT
			if coord in _hover_cells:
				hover_color = Color(0.35, 0.9, 0.45, 0.4) if _hover_valid else Color(0.9, 0.3, 0.3, 0.4)
			cell_node.set_state(residue.has(coord), hover_color)

		var dose := status.get_node("Dose") as Label
		var taste := status.get_node("Taste") as Label
		var residue_label := status.get_node("Residue") as Label
		dose.text = "dosis %d   biaya %d" % [current_dose(), current_cost()] if has_contents() else "belum ada bahan"
		taste.text = "rasa %s" % current_taste_label()
		residue_label.text = "kerak %d" % residue.size()
		residue_label.visible = not residue.is_empty()
	else:
		for child in cells_root.get_children():
			child.visible = false

	var rect := button_rect()
	action.position = rect.position
	action.size = rect.size
	if grid.is_empty():
		action.text = "AMBIL DULU\npilih orang di kasir"
	elif not has_contents():
		action.text = "KUALI KOSONG\nisi bahan dulu"
	elif not panci_has_room:
		action.text = "PANCI PENUH\nambil yang matang"
	else:
		action.text = "SELESAI\njadikan jamu"
	action.disabled = grid.is_empty() or not has_contents() or not panci_has_room
	return

	# Legacy drawing code below is intentionally unreachable while older
	# tests that instantiate KualiGrid without its scene retain their math.
	var font: Font = BODY_FONT
	if grid.is_empty():
		_draw_empty_kuali(font)
		_draw_button()
		return

	var outer := _bounds_rect().grow(18.0)
	draw_rect(outer, Color(0.29, 0.16, 0.09, 0.82))
	draw_rect(outer, Color("8a5a2b"), false, 4.0)
	# Pot interior
	for cell in grid:
		var r := Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL))
		if residue.has(cell):
			draw_rect(r, Color("6b3f2b"))
			draw_circle(r.get_center(), CELL * 0.31, Color("2e211a"))
			draw_circle(r.get_center() + Vector2(-4, -3), CELL * 0.13,
				Color("8a5a3c"))
			draw_line(r.position + Vector2(5, 5), r.end - Vector2(5, 5),
				Color("1b1410"), 3.0)
			draw_line(Vector2(r.end.x - 5, r.position.y + 5),
				Vector2(r.position.x + 5, r.end.y - 5), Color("1b1410"), 3.0)
		else:
			draw_rect(r, Color("6a4935"))
		draw_rect(r, Color("1a120c"), false, 2.0)

	# Hover ghost
	if not _hover_cells.is_empty():
		var col := Color(0.35, 0.9, 0.45, 0.4) if _hover_valid else Color(0.9, 0.3, 0.3, 0.4)
		for cell in _hover_cells:
			if grid.has(cell):
				draw_rect(Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL)), col)

	_draw_status_panel(font, outer)
	_draw_button()


func _draw_empty_kuali(font: Font) -> void:
	var r := Rect2(Vector2.ZERO, EMPTY_SIZE)
	draw_rect(r, Color(0.29, 0.16, 0.09, 0.82))
	draw_rect(r, Color("8a5a2b"), false, 4.0)
	var inner := Rect2(Vector2(18, 32), r.size - Vector2(36, 50))
	draw_rect(inner, Color("2b241d"), false, 2.0)
	draw_line(inner.position + Vector2(20, inner.size.y * 0.5),
		Vector2(inner.end.x - 20, inner.position.y + inner.size.y * 0.5),
		Color("4a4038"), 2.0)
	draw_string(font, inner.position + Vector2(0, inner.size.y * 0.45),
		"ambil pesanan", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 19,
		Color("f2ddb0"))
	draw_string(font, inner.position + Vector2(0, inner.size.y * 0.58),
		"baru kuali dibuka", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 13,
		Color("ccb88f"))


func _draw_status_panel(font: Font, outer: Rect2) -> void:
	var r := Rect2(Vector2(outer.position.x, outer.end.y + 8.0),
		Vector2(STATUS_W, STATUS_H))
	draw_rect(r, Color(0.98, 0.88, 0.61, 0.92))
	draw_rect(r, Color("5a4030"), false, 2.0)

	if pieces.is_empty():
		draw_string(font, r.position + Vector2(10, 20), "ISI KUALI",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("542512"))
		draw_string(font, r.position + Vector2(10, 42),
			"belum ada bahan", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			Color("6f4b35"))
	else:
		draw_string(font, r.position + Vector2(10, 18),
			"ISI KUALI", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color("542512"))
		draw_string(font, r.position + Vector2(10, 36),
			"dosis %d   biaya %d" % [current_dose(), current_cost()],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("8f3b19"))
		draw_string(font, r.position + Vector2(10, 53),
			"rasa %s   panci atur cepat/pelan" % current_taste_label(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("654431"))

	if not residue.is_empty():
		draw_circle(r.position + Vector2(r.size.x - 21, 18), 5.0,
			Color("6b3f2b"))
		draw_string(font, r.position + Vector2(r.size.x - 82, 21),
			"kerak %d" % residue.size(), HORIZONTAL_ALIGNMENT_RIGHT, 70, 11,
			Color("7b3927"))
