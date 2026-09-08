class_name IngredientTray extends Node2D

signal piece_taken(piece: IngredientPiece)

const CELL := IngredientPiece.CELL
const PIECE_SCENE := preload("res://Scenes/Components/ingredient_piece.tscn")

@export var columns: int = 4

var kuali: KualiGrid
var available: Array[IngredientData] = []
var _samples: Array[IngredientPiece] = []
var _loose: Array[IngredientPiece] = []

@onready var _slots_root: Node2D = $Slots
@onready var _loose_root: Node2D = $LoosePieces


func set_available(list: Array[IngredientData]) -> void:
	available = list
	_rebuild()


func _rebuild() -> void:
	_samples.clear()
	_clear_loose()
	var slots := _slots_root.get_children()
	for i in range(slots.size()):
		var slot := slots[i] as IngredientSlot
		if slot == null:
			continue
		if i < available.size():
			slot.bind(available[i])
			_samples.append(slot.piece)
		else:
			slot.visible = false


func _clear_loose() -> void:
	for piece in _loose:
		if is_instance_valid(piece):
			piece.queue_free()
	_loose.clear()


func reset_loose() -> void:
	_clear_loose()


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
			_loose.append(clone)
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
	for cell in piece.cells:
		var rect := Rect2(piece.global_position + Vector2(cell) * CELL, Vector2.ONE * CELL)
		if rect.has_point(pos):
			return true
	return false


func return_piece(piece: IngredientPiece) -> void:
	_loose.erase(piece)
	piece.queue_free()
