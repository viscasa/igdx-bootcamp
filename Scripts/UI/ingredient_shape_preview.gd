@tool
class_name IngredientShapePreview extends Control

@export var preview_cells: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)
]
@export var preview_color: Color = Color("d99b2b")
@export var preview_ingredient_id: StringName = &"kunyit"

@onready var icon_preview: TextureRect = $Icon
@onready var artwork_piece: IngredientPiece = $ArtworkPiece
@onready var recipe_icons: HBoxContainer = $RecipeIcons

var _uses_artwork := false


func _ready() -> void:
	resized.connect(_layout_artwork)
	if Engine.is_editor_hint():
		artwork_piece.set_editor_preview(preview_ingredient_id, preview_cells)
		_uses_artwork = IngredientPiece.artwork_for(preview_ingredient_id) != null
		artwork_piece.visible = _uses_artwork
		_layout_artwork()
	queue_redraw()


func show_ingredient(ingredient: IngredientData) -> void:
	_hide_recipe_icons()
	icon_preview.visible = false
	if ingredient == null:
		preview_cells = []
		_uses_artwork = false
		artwork_piece.visible = false
	else:
		preview_cells = ingredient.shape_cells.duplicate()
		preview_color = ingredient.color
		_uses_artwork = IngredientPiece.artwork_for(ingredient.ingredient_id) != null
		artwork_piece.visible = _uses_artwork
		if _uses_artwork:
			artwork_piece.setup(ingredient, -1)
			var bitterness_pips := artwork_piece.get_node_or_null(
				"VisualRoot/BitternessPips") as Node2D
			if bitterness_pips != null:
				bitterness_pips.visible = false
			_layout_artwork()
	queue_redraw()


func show_icon(texture: Texture2D) -> void:
	_hide_recipe_icons()
	preview_cells = []
	_uses_artwork = false
	artwork_piece.visible = false
	icon_preview.texture = texture
	icon_preview.visible = texture != null
	queue_redraw()


func clear_preview() -> void:
	_hide_recipe_icons()
	preview_cells = []
	_uses_artwork = false
	artwork_piece.visible = false
	icon_preview.visible = false
	queue_redraw()


func show_recipe(ingredients: Array[IngredientData]) -> void:
	preview_cells = []
	_uses_artwork = false
	artwork_piece.visible = false
	icon_preview.visible = false
	recipe_icons.visible = true
	for i in range(recipe_icons.get_child_count()):
		var icon := recipe_icons.get_child(i) as TextureRect
		var texture: Texture2D = null
		if i < ingredients.size():
			texture = IngredientPiece.artwork_for(ingredients[i].ingredient_id)
		icon.texture = texture
		icon.visible = texture != null
	queue_redraw()


func _hide_recipe_icons() -> void:
	if recipe_icons:
		recipe_icons.visible = false


func _draw() -> void:
	if preview_cells.is_empty() or _uses_artwork:
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


func _layout_artwork() -> void:
	if artwork_piece == null or not _uses_artwork:
		return
	var raw_size := artwork_piece.pixel_size()
	if raw_size.x <= 0.0 or raw_size.y <= 0.0:
		return
	var available := (size - Vector2.ONE * 28.0).max(Vector2.ONE)
	var fit := minf(available.x / raw_size.x, available.y / raw_size.y)
	artwork_piece.scale = Vector2.ONE * fit
	artwork_piece.position = (size - raw_size * fit) * 0.5
