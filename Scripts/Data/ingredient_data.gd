@tool
class_name IngredientData extends Resource

## One jamu ingredient: its puzzle shape, the symptoms it treats, and its
## ideal brewing temperature. All khasiat are real traditional uses —
## see Docs/02-Ingredients.md for sources.

@export var ingredient_id: StringName = &""
@export var display_name: String = "Bahan"
@export var latin_name: String = ""

@export_group("Puzzle Shape")
## Cells relative to (0,0). Shape mirrors the plant's real form so players
## can learn to recognize ingredients by silhouette.
@export var shape_cells: Array[Vector2i] = [Vector2i(0, 0)]
@export var color: Color = Color.WHITE

@export_group("Khasiat")
@export var treats: Array[Symptom.Code] = []
## 0 = neutral, 5 = extremely bitter. Drives palatability.
@export_range(0, 5) var bitterness: int = 0
## Sweeteners raise palatability without treating anything.
@export_range(0, 5) var sweetness: int = 0

@export_group("Brewing")
@export_range(0.0, 1.0) var heat_min: float = 0.2
@export_range(0.0, 1.0) var heat_max: float = 0.8
## Fillers and sweeteners tolerate any temperature, so they never shrink
## the pot's heat window. Without this, rice (the 1x1 gap filler) would
## appear in nearly every brew and make most heat windows impossible.
@export var heat_flexible: bool = false

@export_group("Tools")
@export var can_cut: bool = true
@export var can_grind: bool = true

@export_group("Education")
@export_multiline var note: String = ""
@export var source_url: String = ""

@export_group("Economy")
## Cost paid for one pristine piece. Cut pieces pay proportionally to how
## many cells were actually used, making precision and saved offcuts valuable.
@export_range(0, 99) var market_cost: int = 1


func cell_count() -> int:
	return shape_cells.size()


func treats_symptom(code: Symptom.Code) -> bool:
	return code in treats


func heat_center() -> float:
	return (heat_min + heat_max) * 0.5


func heat_label() -> String:
	var c := heat_center()
	if heat_flexible:
		return "fleksibel"
	if c < 0.45:
		return "api kecil"
	if c < 0.7:
		return "api sedang"
	return "api besar"


func cost_for_cells(cells: int) -> int:
	if shape_cells.is_empty():
		return market_cost
	return maxi(1, ceili(float(market_cost * cells) / shape_cells.size()))


## Builds an ingredient without needing a .tres file — used by IngredientDB.
static func create(
	id: StringName,
	name_: String,
	latin: String,
	cells: Array[Vector2i],
	col: Color,
	treats_: Array[Symptom.Code],
	bitter: int,
	heat: Vector2,
	note_: String
) -> IngredientData:
	var d := IngredientData.new()
	d.ingredient_id = id
	d.display_name = name_
	d.latin_name = latin
	d.shape_cells = cells
	d.color = col
	d.treats = treats_
	d.bitterness = bitter
	d.heat_min = heat.x
	d.heat_max = heat.y
	d.note = note_
	return d
