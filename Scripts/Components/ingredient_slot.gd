@tool
class_name IngredientSlot extends Node2D

@export_range(0, 7, 1) var preview_variant := 0:
	set(value):
		preview_variant = value
		_apply_editor_preview()
@export var preview_color := Color("c4553c"):
	set(value):
		preview_color = value
		_apply_editor_preview()
@export var preview_name := "Jahe Merah":
	set(value):
		preview_name = value
		_apply_editor_preview()

@onready var piece: IngredientPiece = $Piece
@onready var name_label: Label = $NameLabel
@onready var dose_label: Label = $DoseLabel
@onready var taste_label: Label = $TasteLabel


func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_editor_preview()


func bind(ingredient: IngredientData) -> void:
	visible = ingredient != null
	if ingredient == null:
		return
	piece.setup(ingredient, -1)
	name_label.text = ingredient.display_name
	dose_label.text = "dosis +%d  biaya %d" % [ingredient.shape_cells.size(), ingredient.market_cost]
	taste_label.text = "rasa %s" % taste_label_for(ingredient)
	var bottom := float(GridLogic.shape_size(ingredient.shape_cells).y * IngredientPiece.CELL)
	name_label.position.y = bottom + 7.0
	dose_label.position.y = bottom + 23.0
	taste_label.position.y = bottom + 37.0


func _apply_editor_preview() -> void:
	if not is_inside_tree():
		return
	var shapes: Array[Array] = [
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 0)],
		[Vector2i(0, 0)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	]
	var raw_shape: Array = shapes[clampi(preview_variant, 0, shapes.size() - 1)]
	var shape: Array[Vector2i] = []
	for cell in raw_shape:
		shape.append(cell as Vector2i)
	var holder := get_node_or_null("Piece/Cells")
	if holder:
		for i in range(holder.get_child_count()):
			var cell := holder.get_child(i) as IngredientCell
			cell.visible = i < shape.size()
			if i < shape.size():
				cell.position = Vector2(shape[i]) * IngredientPiece.CELL
				cell.set_cell_color(preview_color)
	var h := float(GridLogic.shape_size(shape).y * IngredientPiece.CELL)
	var label := get_node_or_null("NameLabel") as Label
	var dose := get_node_or_null("DoseLabel") as Label
	var taste := get_node_or_null("TasteLabel") as Label
	if label:
		label.text = preview_name
		label.position.y = h + 7.0
	if dose:
		dose.text = "dosis +%d" % shape.size()
		dose.position.y = h + 23.0
	if taste:
		taste.text = "rasa netral"
		taste.position.y = h + 37.0


static func taste_label_for(ingredient: IngredientData) -> String:
	if ingredient.ingredient_id == &"gula_jawa":
		return "manis"
	if ingredient.ingredient_id == &"asam_jawa":
		return "asam"
	if ingredient.bitterness >= 4:
		return "sgt pahit"
	if ingredient.bitterness >= 2:
		return "pahit"
	return "netral"
