extends Control

const PIECE_CELL_SIZE := 58.0
const PIECE_CELL_GAP := 4.0
const PIECE_CELL_PITCH := PIECE_CELL_SIZE + PIECE_CELL_GAP

const SHAPES: Array[Dictionary] = [
	{"name": "I", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]},
	{"name": "O", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"name": "T", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]},
	{"name": "L", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]},
	{"name": "J", "cells": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)]},
	{"name": "S", "cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"name": "Z", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]},
	{"name": "SMALL L", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"name": "DOT", "cells": [Vector2i(0, 0)]},
]

@export_group("Piece Visual")
@export var piece_color := Color("#55c7f3")
@export var invalid_piece_color := Color("#ff6b7a")
@export var piece_texture: Texture2D = preload("res://icon.svg")

@onready var board = $Board
@onready var current_piece: GridContainer = $CurrentPiece
@onready var piece_area: PanelContainer = $PieceTray/Content/PieceArea
@onready var shape_name_label: Label = $PieceTray/Content/ShapeNameLabel
@onready var score_label: Label = $HUD/ScoreLabel
@onready var message_label: Label = $HUD/StatusPanel/VBox/MessageLabel
@onready var progress_label: Label = $HUD/StatusPanel/VBox/ProgressLabel

var current_cells: Array[Vector2i] = []
var current_name := ""
var piece_home_global_position := Vector2.ZERO
var drag_offset := Vector2.ZERO
var dragging := false
var hover_origin := Vector2i(-99, -99)
var score := 0
var placed_count := 0


func _ready() -> void:
	piece_area.resized.connect(_on_piece_area_resized)
	randomize()
	_spawn_random_piece()
	call_deferred("_center_piece_in_tray")
	_update_hud("Tarik blok ke papan")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_piece"):
		_rotate_piece()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _point_hits_current_piece(event.position):
			dragging = true
			drag_offset = event.position - current_piece.global_position
			_move_piece(event.position)
			_update_hud("Lepaskan pada posisi yang valid")
			get_viewport().set_input_as_handled()
		elif not event.pressed and dragging:
			_finish_drag()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		_move_piece(event.position)


func _spawn_random_piece() -> void:
	var shape: Dictionary = SHAPES.pick_random()
	current_name = shape["name"]
	current_cells.clear()
	for cell: Vector2i in shape["cells"]:
		current_cells.append(cell)
	_normalize_piece()
	shape_name_label.text = current_name
	dragging = false
	hover_origin = Vector2i(-99, -99)
	_update_piece_nodes()
	_center_piece_in_tray()


func _rotate_piece() -> void:
	var rotated: Array[Vector2i] = []
	for cell: Vector2i in current_cells:
		rotated.append(Vector2i(-cell.y, cell.x))
	current_cells = rotated
	_normalize_piece()
	_update_piece_nodes()
	if dragging:
		_update_board_preview()
	else:
		_center_piece_in_tray()
	_update_hud("Blok diputar 90°")


func _normalize_piece() -> void:
	var min_x := 99
	var min_y := 99
	for cell: Vector2i in current_cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
	for index: int in current_cells.size():
		current_cells[index] -= Vector2i(min_x, min_y)


func _update_piece_nodes() -> void:
	var buttons := current_piece.get_children()
	for index: int in buttons.size():
		var button := buttons[index] as Button
		var coordinate := Vector2i(index % 4, index / 4)
		var active := current_cells.has(coordinate)
		button.icon = piece_texture if active else null
		button.modulate = piece_color if active else Color(1.0, 1.0, 1.0, 0.0)


func _piece_dimensions() -> Vector2i:
	var dimensions := Vector2i.ONE
	for cell: Vector2i in current_cells:
		dimensions.x = maxi(dimensions.x, cell.x + 1)
		dimensions.y = maxi(dimensions.y, cell.y + 1)
	return dimensions


func _center_piece_in_tray() -> void:
	var dimensions := Vector2(_piece_dimensions())
	var visual_size := dimensions * PIECE_CELL_SIZE + (dimensions - Vector2.ONE) * PIECE_CELL_GAP
	piece_home_global_position = (piece_area.get_global_rect().get_center() - visual_size * 0.5).round()
	current_piece.global_position = piece_home_global_position
	current_piece.modulate = Color.WHITE


func _on_piece_area_resized() -> void:
	if not dragging:
		_center_piece_in_tray()


func _point_hits_current_piece(point: Vector2) -> bool:
	for cell: Vector2i in current_cells:
		var cell_rect := Rect2(
			current_piece.global_position + Vector2(cell) * PIECE_CELL_PITCH,
			Vector2.ONE * PIECE_CELL_SIZE
		)
		if cell_rect.has_point(point):
			return true
	return false


func _move_piece(mouse_position: Vector2) -> void:
	current_piece.global_position = mouse_position - drag_offset
	_update_board_preview()


func _update_board_preview() -> void:
	hover_origin = board.cell_from_global_position(current_piece.global_position)
	var valid: bool = board.can_place(current_cells, hover_origin)
	board.show_preview(current_cells, hover_origin, valid)
	current_piece.modulate = Color.WHITE if valid else invalid_piece_color


func _finish_drag() -> void:
	var valid: bool = board.can_place(current_cells, hover_origin)
	if valid:
		var cleared: int = board.place_piece(current_cells, hover_origin)
		placed_count += 1
		score += current_cells.size() * 10 + cleared * 100
		var result_message := "Placement berhasil! Blok baru siap"
		if cleared > 0:
			result_message = "%d garis bersih! +%d" % [cleared, cleared * 100]
		_spawn_random_piece()
		_update_hud(result_message)
	else:
		board.clear_preview()
		current_piece.global_position = piece_home_global_position
		current_piece.modulate = Color.WHITE
		dragging = false
		_update_hud("Belum bisa ditaruh di sana")


func _update_hud(message: String) -> void:
	score_label.text = "SCORE  %05d" % score
	message_label.text = message
	progress_label.text = "Blok ditempatkan: %d  •  Baris/kolom penuh akan dibersihkan" % placed_count
