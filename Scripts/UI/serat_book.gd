class_name SeratBook extends Control

enum Page { SYMPTOMS, INGREDIENTS, RECIPES }

@onready var symptom_tab: Button = %SymptomTab
@onready var ingredient_tab: Button = %IngredientTab
@onready var recipe_tab: Button = %RecipeTab
@onready var symptom_grid: GridContainer = %SymptomGrid
@onready var ingredient_list: ItemList = %IngredientList
@onready var recipe_list: ItemList = %RecipeList
@onready var shape_preview: IngredientShapePreview = %ShapePreview
@onready var entry_title: Label = %EntryTitle
@onready var latin_label: Label = %LatinLabel
@onready var mode_hint: Label = %ModeHint
@onready var dose_value: Label = $Book/Margin/Layout/Columns/Detail/Stats/Dose/Value
@onready var cost_value: Label = $Book/Margin/Layout/Columns/Detail/Stats/Cost/Value
@onready var bitter_value: Label = $Book/Margin/Layout/Columns/Detail/Stats/Bitter/Value
@onready var heat_value: Label = $Book/Margin/Layout/Columns/Detail/Stats/Heat/Value
@onready var stats: HBoxContainer = $Book/Margin/Layout/Columns/Detail/Stats
@onready var treats_badges: HBoxContainer = %TreatsBadges
@onready var note_label: RichTextLabel = %NoteLabel
@onready var close_button: Button = %CloseButton
@onready var recipe_label: Label = %RecipeLabel

var _page: Page = Page.SYMPTOMS
var _selected_symptoms: Array[Symptom.Code] = []
var _focused_symptom: int = -1
var _shown_recipes: Array[Dictionary] = []
var _shown: Array[IngredientData] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(symptom_grid.get_child_count()):
		var button := symptom_grid.get_child(i) as Button
		if button:
			button.text = Symptom.display_name(i as Symptom.Code)
			button.pressed.connect(_toggle_symptom.bind(i))
	symptom_tab.pressed.connect(_set_page.bind(Page.SYMPTOMS))
	ingredient_tab.pressed.connect(_set_page.bind(Page.INGREDIENTS))
	recipe_tab.pressed.connect(_set_page.bind(Page.RECIPES))
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
	_set_page(_page)
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


func _set_page(page: Page) -> void:
	_page = page
	symptom_grid.visible = page == Page.SYMPTOMS
	ingredient_list.visible = page == Page.INGREDIENTS
	recipe_list.visible = page == Page.RECIPES
	symptom_tab.button_pressed = page == Page.SYMPTOMS
	ingredient_tab.button_pressed = page == Page.INGREDIENTS
	recipe_tab.button_pressed = page == Page.RECIPES
	_sync_symptom_buttons()
	if page == Page.INGREDIENTS and not _shown.is_empty():
		_select_ingredient(maxi(ingredient_list.get_selected_items()[0], 0) \
			if not ingredient_list.get_selected_items().is_empty() else 0)
	elif page == Page.RECIPES and not _shown_recipes.is_empty():
		_select_recipe(maxi(recipe_list.get_selected_items()[0], 0) \
			if not recipe_list.get_selected_items().is_empty() else 0)
	elif page == Page.SYMPTOMS:
		if _focused_symptom >= 0:
			_show_symptom(_focused_symptom as Symptom.Code)
		else:
			_show_symptom_selection_hint()


func _toggle_symptom(code: int) -> void:
	var symptom := code as Symptom.Code
	var button := symptom_grid.get_child(code) as Button
	if button != null and button.button_pressed:
		if symptom not in _selected_symptoms:
			_selected_symptoms.append(symptom)
		_focused_symptom = code
	else:
		_selected_symptoms.erase(symptom)
		_focused_symptom = int(_selected_symptoms.back()) \
			if not _selected_symptoms.is_empty() else -1
	_sync_symptom_buttons()
	_refresh_ingredient_list()
	if _focused_symptom >= 0:
		_show_symptom(_focused_symptom as Symptom.Code)
	else:
		_show_symptom_selection_hint()


func _sync_symptom_buttons() -> void:
	for i in range(symptom_grid.get_child_count()):
		var button := symptom_grid.get_child(i) as Button
		if button != null:
			button.button_pressed = (i as Symptom.Code) in _selected_symptoms


func _refresh_ingredient_list() -> void:
	_shown.clear()
	ingredient_list.clear()
	for ing in IngredientDB.available_on_day(GameState.day):
		var matches := false
		for symptom in _selected_symptoms:
			if ing.treats_symptom(symptom):
				matches = true
				break
		_shown.append(ing)
		ingredient_list.add_item(("◆ " if matches else "  ") + ing.display_name)
		var idx := ingredient_list.get_item_count() - 1
		ingredient_list.set_item_custom_fg_color(idx,
			Color("7a4a16") if matches else Color("4b2a18"))


func _show_symptom_selection_hint() -> void:
	stats.visible = false
	shape_preview.clear_preview()
	entry_title.text = "Pilih gejala"
	latin_label.text = "INDEKS GEJALA"
	mode_hint.text = "Pilih satu atau beberapa gejala untuk menandai bahan terkait."
	_set_treat_badges([])
	note_label.text = "[font_size=20]Diamond oranye di halaman Bahan mengikuti gejala yang kamu pilih.[/font_size]"


func _select_ingredient(index: int) -> void:
	if index < 0 or index >= _shown.size():
		return
	ingredient_list.select(index)
	_show_ingredient(_shown[index])


func _select_recipe(index: int) -> void:
	if index < 0 or index >= _shown_recipes.size():
		return
	recipe_list.select(index)
	_show_recipe(_shown_recipes[index])


func _show_symptom(code: Symptom.Code) -> void:
	var badge := symptom_grid.get_child(int(code)) as Button
	shape_preview.show_icon(badge.icon if badge else null)
	stats.visible = false
	entry_title.text = Symptom.display_name(code)
	latin_label.text = "INDEKS GEJALA"
	mode_hint.text = Symptom.description(code).replace("kata kunci: ", "Kata kunci · ")
	_set_stat_cards("—", "—", "—", "—")
	_set_treat_badges([code])
	var matches := _ingredients_for_symptom(code)
	note_label.text = "[font_size=22]Cari tanda ini dari ucapan customer.[/font_size]\n\nBahan yang biasa dipakai: [b]%s[/b]" % [
		", ".join(matches) if not matches.is_empty() else "belum ditemukan di Serat"]


func _show_ingredient(ing: IngredientData) -> void:
	stats.visible = true
	shape_preview.show_ingredient(ing)
	entry_title.text = ing.display_name
	latin_label.text = ing.latin_name
	mode_hint.text = "Ditemukan sejak hari %d" % IngredientDB.unlock_day(ing.ingredient_id)
	_set_stat_cards(
		"+%d TAKARAN" % ing.cell_count(),
		"%d DUIT" % ing.market_cost,
		"PAHIT %s" % ("●".repeat(ing.bitterness) + "○".repeat(5 - ing.bitterness)),
		ing.heat_label().to_upper()
	)
	_set_treat_badges(ing.treats)
	note_label.text = "[font_size=20]%s[/font_size]" % ing.note


func _show_recipe(recipe: Dictionary) -> void:
	stats.visible = true
	shape_preview.clear_preview()
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
	latin_label.text = "RESEP WARISAN"
	mode_hint.text = " + ".join(ingredient_names)
	_set_stat_cards("★", "%d BAHAN" % ids.size(), "BONUS", "WARISAN")
	_set_treat_badges([])
	var found := name in GameState.discovered_recipes
	var status := "STAMP DITEMUKAN" if found else (
		"Siap diracik" if unlocked else "Bahan belum lengkap")
	note_label.text = "[font_size=22][b]%s[/b][/font_size]\n%s\n\n%s" % [
		status, String(recipe["effect"]), String(recipe["lore"])]


func _set_stat_cards(dose: String, cost: String, bitter: String, heat: String) -> void:
	dose_value.text = dose
	cost_value.text = cost
	bitter_value.text = bitter
	heat_value.text = heat


func _set_treat_badges(codes: Array) -> void:
	for child in treats_badges.get_children():
		child.queue_free()
	if codes.is_empty():
		var empty := Label.new()
		empty.text = "Eksperimen dan temukan kombinasinya"
		treats_badges.add_child(empty)
		return
	for value in codes:
		var code := int(value) as Symptom.Code
		var badge := Label.new()
		badge.text = "  %s  " % Symptom.display_name(code)
		badge.add_theme_color_override("font_color", Color("3b190b"))
		badge.add_theme_font_size_override("font_size", 15)
		var style := StyleBoxFlat.new()
		style.bg_color = Symptom.color(code).lightened(0.28)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		badge.add_theme_stylebox_override("normal", style)
		treats_badges.add_child(badge)


func _ingredients_for_symptom(code: Symptom.Code) -> Array[String]:
	var names: Array[String] = []
	for ing in IngredientDB.available_on_day(GameState.day):
		if ing.treats_symptom(code):
			names.append(ing.display_name)
	return names


func _refresh_recipes() -> void:
	var known := GameState.discovered_recipes
	_shown_recipes = RecipeEvaluator.heritage_recipes()
	recipe_list.clear()
	for recipe in _shown_recipes:
		var name := String(recipe["name"])
		var found := name in known
		recipe_list.add_item(("◆ " if found else "◇ ") + (name if found else "Resep belum dikenal"))
		var idx := recipe_list.get_item_count() - 1
		recipe_list.set_item_custom_fg_color(idx,
			Color("7a4a16") if found else Color("7b6b58"))
	var stamps: Array[String] = []
	for i in range(4):
		stamps.append("◆" if i < known.size() else "◇")
	recipe_label.text = "RESEP WARISAN  %d/4    %s" % [
		known.size(), "  ".join(stamps)]
