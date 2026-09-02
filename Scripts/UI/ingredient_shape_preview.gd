@tool
class_name IngredientShapePreview extends Control

@export var preview_cells: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)
]
@export var preview_color: Color = Color("d99b2b")

@onready var icon_preview: TextureRect = $Icon


func _ready() -> void:
	queue_redraw()


func show_ingredient(ingredient: IngredientData) -> void:
	icon_preview.visible = false
	if ingredient == null:
		preview_cells = []
	else:
		preview_cells = ingredient.shape_cells.duplicate()
		preview_color = ingredient.color
	queue_redraw()


func show_icon(texture: Texture2D) -> void:
	preview_cells = []
	icon_preview.texture = texture
	icon_preview.visible = texture != null
	queue_redraw()


func clear_preview() -> void:
	preview_cells = []
	icon_preview.visible = false
	queue_redraw()


func _draw() -> void:
	if preview_cells.is_empty():
		return
	var min_cell := preview_cells[0]
	var max_cell := preview_cells[0]
	for cell in preview_cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	var dimensions := max_cell - min_cell + Vector2i.ONE
	var cell_size := minf(
		(size.x - 24.0) / maxf(dimensions.x, 1),
		(size.y - 24.0) / maxf(dimensions.y, 1)
	)
	cell_size = minf(cell_size, 54.0)
	var drawing_size := Vector2(dimensions) * cell_size
	var origin := (size - drawing_size) * 0.5
	for cell in preview_cells:
		var at := origin + Vector2(cell - min_cell) * cell_size
		var rect := Rect2(at + Vector2.ONE * 2.0, Vector2.ONE * (cell_size - 4.0))
		draw_rect(rect, preview_color)
		draw_rect(rect, Color("5a2b18"), false, 3.0)
		draw_circle(rect.position + Vector2(cell_size * 0.32, cell_size * 0.28),
			maxf(cell_size * 0.07, 2.0), preview_color.lightened(0.35))
