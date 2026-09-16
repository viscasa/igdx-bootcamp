class_name IngredientTray extends Node2D

signal piece_taken(piece: IngredientPiece)

const CELL := IngredientPiece.CELL
const PIECE_SCENE := preload("res://Scenes/Components/ingredient_piece.tscn")

@export var columns: int = 4

var kuali: KualiGrid
var available: Array[IngredientData] = []
var _samples: Array[IngredientPiece] = []
var _loose: Array[IngredientPiece] = []
var _rack_height := 0.0

@onready var _slots_root: Node2D = $Slots
@onready var _loose_root: Node2D = $LoosePieces
@onready var _loose_title: Label = $LooseTitle


func set_available(list: Array[IngredientData]) -> void:
	available = list
	_rebuild()


func _rebuild() -> void:
	_samples.clear()
	_clear_loose()
	var slots := _slots_root.get_children()
	var content_height := 0.0
	var row_y := 0.0
	var row_height := 0.0
	for i in range(slots.size()):
		var slot := slots[i] as IngredientSlot
		if slot == null:
			continue
		if i < available.size():
			if i > 0 and i % columns == 0:
				row_y += row_height + 16.0
				row_height = 0.0
			slot.bind(available[i])
			slot.position.y = row_y
			_samples.append(slot.piece)
			row_height = maxf(row_height, slot.piece.pixel_size().y + 82.0)
			content_height = row_y + row_height
		else:
			slot.visible = false
	_rack_height = content_height
	_layout_loose()


func _clear_loose() -> void:
	for piece in _loose:
		if is_instance_valid(piece):
			piece.queue_free()
	_loose.clear()


func reset_loose() -> void:
	_clear_loose()
	_layout_loose()


func loose_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for piece in _loose:
		if not is_instance_valid(piece):
			continue
		snapshots.append({
			"data": piece.data,
			"cells": piece.cells.duplicate(),
			"artwork_cells": piece.artwork_cells.duplicate(),
			"artwork_size": piece.artwork_grid_size,
			"rotation": piece.artwork_rotation_steps,
			"paid": piece.paid,
			"was_cut": piece.was_cut,
		})
	return snapshots


func restore_loose(snapshots: Array[Dictionary]) -> void:
	_clear_loose()
	for snapshot in snapshots:
		var piece := PIECE_SCENE.instantiate() as IngredientPiece
		piece.setup(snapshot["data"], kuali.next_id())
		var cells: Array[Vector2i] = []
		cells.assign(snapshot["cells"])
		var artwork_cells: Array[Vector2i] = []
		artwork_cells.assign(snapshot["artwork_cells"])
		piece.cells = cells
		piece.setup_visual_mapping(artwork_cells, snapshot["artwork_size"],
			int(snapshot["rotation"]))
		piece.paid = bool(snapshot["paid"])
		piece.was_cut = bool(snapshot["was_cut"])
		_loose_root.add_child(piece)
		_loose.append(piece)
	_layout_loose()


func piece_at(pos: Vector2) -> IngredientPiece:
	for piece in _loose:
		if is_instance_valid(piece) and _hits(piece, pos):
			return piece

	for sample in _samples:
		if is_instance_valid(sample) and _hits(sample, pos):
			var clone := PIECE_SCENE.instantiate() as IngredientPiece
			clone.setup(sample.data, kuali.next_id())
			_loose_root.add_child(clone)
			clone.global_position = sample.global_position
			piece_taken.emit(clone)
			return clone
	return null


func has_piece_at(pos: Vector2) -> bool:
	for piece in _loose:
		if is_instance_valid(piece) and _hits(piece, pos):
			return true
	for sample in _samples:
		if is_instance_valid(sample) and _hits(sample, pos):
			return true
	return false


func _hits(piece: IngredientPiece, pos: Vector2) -> bool:
	var scroll := get_parent().get_parent() as ScrollContainer
	if scroll != null and not scroll.get_global_rect().has_point(pos):
		return false
	var local := piece.to_local(pos)
	for cell in piece.cells:
		var rect := Rect2(Vector2(cell) * CELL, Vector2.ONE * CELL)
		if rect.has_point(local):
			return true
	return false


func return_piece(piece: IngredientPiece) -> void:
	_loose.erase(piece)
	if not is_instance_valid(piece):
		return
	if piece.was_cut or piece.paid:
		if piece.get_parent():
			piece.get_parent().remove_child(piece)
		_loose_root.add_child(piece)
		piece.state = IngredientPiece.State.IN_TRAY
		piece.z_index = 1
		_loose.append(piece)
		_layout_loose()
	else:
		piece.queue_free()


func take_piece(piece: IngredientPiece) -> void:
	var was_parked := piece in _loose
	_loose.erase(piece)
	if was_parked:
		_layout_loose()


func _layout_loose() -> void:
	_loose_title.visible = not _loose.is_empty()
	_loose_title.position.y = _rack_height + 8.0
	var y := _rack_height + 44.0
	var row_height := 0.0
	for i in range(_loose.size()):
		var piece := _loose[i]
		if not is_instance_valid(piece):
			continue
		var column := i % columns
		if column == 0 and i > 0:
			y += row_height + 18.0
			row_height = 0.0
		piece.position = Vector2(column * 135.0, y)
		row_height = maxf(row_height, piece.pixel_size().y)
	var content := get_parent() as Control
	if content != null:
		var used_height := _rack_height if _loose.is_empty() \
			else y + row_height + 18.0
		content.custom_minimum_size.y = used_height + position.y
