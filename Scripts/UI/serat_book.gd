class_name SeratBook extends Control

## Ingredient and symptom reference. The Serat is a growing notebook:
## symptoms live on the left, discovered ingredients on the right, and the
## middle page explains whichever thing the player clicked.

@onready var symptom_grid: GridContainer = %SymptomGrid
@onready var ingredient_list: ItemList = %IngredientList
@onready var entry_title: Label = %EntryTitle
@onready var latin_label: Label = %LatinLabel
@onready var stats_label: Label = %StatsLabel
@onready var treats_label: Label = %TreatsLabel
@onready var note_label: RichTextLabel = %NoteLabel
@onready var index_description: Label = %IndexDescription
@onready var close_button: Button = %CloseButton
@onready var recipe_label: Label = %RecipeLabel
@onready var recipe_list: ItemList = %RecipeList

var _selected_symptom: int = -1
var _selected_ingredient: int = -1
var _shown_recipes: Array[Dictionary] = []
var _shown: Array[IngredientData] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(symptom_grid.get_child_count()):
		var button := symptom_grid.get_child(i) as Button
		if button:
			button.text = Symptom.display_name(i as Symptom.Code)
			button.modulate = Symptom.color(i as Symptom.Code)
			button.pressed.connect(_select_symptom.bind(i))
	ingredient_list.item_selected.connect(_select_ingredient)
	recipe_list.item_selected.connect(_select_recipe)
	close_button.pressed.connect(close)
	visible = false


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	GameState.study_open = true
	_refresh_recipes()
	_refresh_ingredient_list()
	if _selected_symptom < 0:
		_select_symptom(Symptom.Code.PENCERNAAN)
	else:
		_show_symptom(_selected_symptom as Symptom.Code)
	grab_focus()


func close() -> void:
	visible = false
	GameState.study_open = false


func _exit_tree() -> void:
	if GameState:
		GameState.study_open = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_F:
			toggle()
			get_viewport().set_input_as_handled()
		elif visible and key == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func _select_symptom(code: int) -> void:
	_selected_symptom = code
	_selected_ingredient = -1
	_refresh_ingredient_list()
	_show_symptom(code as Symptom.Code)


func _refresh_ingredient_list() -> void:
	_shown.clear()
	ingredient_list.clear()
	for ing in IngredientDB.available_on_day(GameState.day):
		var matches := _selected_symptom >= 0 \
			and ing.treats_symptom(_selected_symptom as Symptom.Code)
		var mark := "* " if matches else "  "
		var label := "%s%s   +%d dosis   %d duit" % [
			mark, ing.display_name, ing.cell_count(), ing.market_cost]
		_shown.append(ing)
		ingredient_list.add_item(label)
		var idx := ingredient_list.get_item_count() - 1
		if matches:
			ingredient_list.set_item_custom_fg_color(idx, Color("ffd36f"))
		elif ing.treats.is_empty():
			ingredient_list.set_item_custom_fg_color(idx, Color("c9b892"))
		else:
			ingredient_list.set_item_custom_fg_color(idx, Color("e8dcc0"))


func _select_ingredient(index: int) -> void:
	if index >= 0 and index < _shown.size():
		_selected_ingredient = index
		_show_ingredient(_shown[index])


func _select_recipe(index: int) -> void:
	if index >= 0 and index < _shown_recipes.size():
		_show_recipe(_shown_recipes[index])


func _show_symptom(code: Symptom.Code) -> void:
	var matches := _ingredients_for_symptom(code)
	entry_title.text = "Gejala: %s" % Symptom.display_name(code)
	latin_label.text = ""
	stats_label.text = Symptom.description(code)
	treats_label.text = "Bahan bertanda * di kanan cocok untuk gejala ini."
	note_label.text = "Dengarkan kata-kata pelanggan, lalu cocokkan dengan gejala ini.\n\nBahan yang biasa dipakai: %s" % [
		", ".join(matches) if not matches.is_empty() else "belum ditemukan di Serat"]


func _show_ingredient(ing: IngredientData) -> void:
	entry_title.text = ing.display_name
	latin_label.text = ing.latin_name
	var bitter := "netral" if ing.bitterness == 0 else "pahit %d/5" % ing.bitterness
	stats_label.text = "Takaran +%d | biaya %d | rasa %s | ditemukan hari %d" % [
		ing.cell_count(), ing.market_cost, bitter,
		IngredientDB.unlock_day(ing.ingredient_id)]
	var names: Array[String] = []
	for s in ing.treats:
		names.append(Symptom.display_name(s))
	treats_label.text = "Penggunaan tradisional: %s" % (
		", ".join(names) if not names.is_empty() else "pemanis/penyeimbang rasa")
	note_label.text = ing.note


func _show_recipe(recipe: Dictionary) -> void:
	var name := String(recipe["name"])
	var ids: Array = recipe["ids"]
	var ingredient_names: Array[String] = []
	var unlocked := true
	for id in ids:
		var ing := IngredientDB.get_by_id(id)
		if ing != null:
			ingredient_names.append(ing.display_name)
			if IngredientDB.unlock_day(id) > GameState.day:
				unlocked = false

	entry_title.text = name
	latin_label.text = "Resep warisan"
	stats_label.text = "Bahan: %s" % ", ".join(ingredient_names)
	treats_label.text = String(recipe["effect"])
	var found := name in GameState.discovered_recipes
	var status := "STAMP DITEMUKAN - sudah masuk Serat." if found else (
		"Semua bahan sudah ada; coba racik untuk membuka penanda." if unlocked
		else "Sebagian bahan belum ditemukan di hari ini.")
	note_label.text = "%s\n\n%s" % [status, String(recipe["lore"])]


func _ingredients_for_symptom(code: Symptom.Code) -> Array[String]:
	var names: Array[String] = []
	for ing in IngredientDB.available_on_day(GameState.day):
		if ing.treats_symptom(code):
			names.append(ing.display_name)
	return names


func _refresh_recipes() -> void:
	var known := GameState.discovered_recipes
	var slots: Array[String] = []
	_shown_recipes = RecipeEvaluator.heritage_recipes()
	recipe_list.clear()
	for recipe in _shown_recipes:
		var name := String(recipe["name"])
		var found := name in known
		slots.append(name if found else "???")
		recipe_list.add_item(("%s" if found else "? %s") % name)
		var idx := recipe_list.get_item_count() - 1
		recipe_list.set_item_custom_fg_color(idx,
			Color("ffd36f") if found else Color("9a8f80"))
	recipe_label.text = "RESEP WARISAN  %d/4  -  %s" % [
		known.size(), "  -  ".join(slots)]
