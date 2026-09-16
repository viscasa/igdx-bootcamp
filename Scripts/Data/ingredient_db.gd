extends Node

## Autoload: the 12 jamu ingredients, built in code so the prototype needs no
## .tres authoring. Shapes deliberately echo each plant's real form — a
## memory aid, not decoration.
##
## Khasiat sourced in Docs/02-Ingredients.md. Do not invent new ones.

const S := Symptom.Code
const PLAYABLE_IDS: Array[StringName] = [&"jahe_merah", &"kunyit", &"kencur", &"beras", &"asam_jawa", &"gula_jawa"]

var all: Array[IngredientData] = []
var _by_id: Dictionary = {}


func _ready() -> void:
	_build()
	for ing in all:
		_by_id[ing.ingredient_id] = ing


func get_by_id(id: StringName) -> IngredientData:
	return _by_id.get(id)


## Ingredients available on a given day. New plants are introduced in small
## handfuls so the Serat feels like a growing notebook, not a wall of names.
func available_on_day(day: int) -> Array[IngredientData]:
	var out: Array[IngredientData] = []
	for ing in all:
		if ing.ingredient_id in PLAYABLE_IDS and int(UNLOCK_DAY.get(ing.ingredient_id, 1)) <= day:
			out.append(ing)
	return out


func unlock_names_on_day(day: int) -> Array[String]:
	var out: Array[String] = []
	for ing in all:
		if ing.ingredient_id in PLAYABLE_IDS and int(UNLOCK_DAY.get(ing.ingredient_id, 1)) == day:
			out.append(ing.display_name)
	return out


func unlock_day(id: StringName) -> int:
	return int(UNLOCK_DAY.get(id, 1))


func supports_symptom(code: Symptom.Code) -> bool:
	for ing in available_on_day(1):
		if ing.treats_symptom(code):
			return true
	return false


func supports_request(variant: RequestVariant) -> bool:
	for code in variant.symptoms:
		if not supports_symptom(code):
			return false
	return true


func next_unlock_text(after_day: int) -> String:
	var names := unlock_names_on_day(after_day + 1)
	return "Bahan baru besok: %s." % ", ".join(names) if not names.is_empty() else ""


const UNLOCK_DAY := {
	&"kunyit": 1,
	&"jahe_merah": 1,
	&"kencur": 1,
	&"beras": 1,
	&"asam_jawa": 1,
	&"gula_jawa": 1,
	&"brotowali": 2,
	&"temulawak": 3,
	&"sambiloto": 4,
	&"temu_ireng": 4,
	&"daun_sirih": 4,
	&"kayu_manis": 4,
}


const ADVANCED: Array[StringName] = [
	&"sambiloto", &"temu_ireng", &"daun_sirih", &"kayu_manis"
]


func _build() -> void:
	_build_list()
	# Fillers and sweeteners must not constrain the pot's temperature —
	# they appear in most brews, so letting them narrow the window would
	# make the heat mechanic unplayable.
	for id in [&"beras", &"gula_jawa"]:
		for ing in all:
			if ing.ingredient_id == id:
				ing.heat_flexible = true

	# A small, readable economy: large and rare roots cost more. Supply is
	# still unlimited so a bad shopping decision can never soft-lock a run;
	# cost only changes the profit and rewards precise cutting.
	var costs := {
		&"brotowali": 4, &"jahe_merah": 4, &"kunyit": 3,
		&"kencur": 2, &"temulawak": 6, &"beras": 1,
		&"asam_jawa": 3, &"gula_jawa": 2, &"sambiloto": 6,
		&"temu_ireng": 7, &"daun_sirih": 5, &"kayu_manis": 4,
	}
	for ing in all:
		ing.market_cost = int(costs.get(ing.ingredient_id, 2))


func _build_list() -> void:
	all = [
		# ─────────── CORE 8 ───────────

		# Long trailing vine with a knobbly stem → 1x4 straight line.
		IngredientData.create(
			&"brotowali", "Brotowali", "Tinospora crispa",
			[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
			Color("6b7f4a"),
			[S.DEMAM, S.KULIT, S.NAFSU_MAKAN],
			5, Vector2(0.65, 0.92),
			"Batang pahit berbintil. Dipercaya menurunkan panas (antipiretik) dan meredakan peradangan."
		),

		# Rhizome branches into fingers → L shape.
		IngredientData.create(
			&"jahe_merah", "Jahe Merah", "Zingiber officinale var. rubrum",
			[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
			Color("c4553c"),
			[S.DINGIN, S.LEMAH, S.NYERI_SENDI, S.BATUK],
			2, Vector2(0.74, 0.98),
			"Minyak atsiri tinggi. Menghangatkan tubuh, meredakan masuk angin dan pegal linu."
		),

		# Fat round rhizome → 2x2.
		IngredientData.create(
			&"kunyit", "Kunyit", "Curcuma longa",
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
			Color("d99b2b"),
			[S.PENCERNAAN, S.NYERI_SENDI, S.WANITA],
			1, Vector2(0.24, 0.48),
			"Kurkumin: antiinflamasi dan antioksidan. Kurkumin rusak bila terlalu panas."
		),

		# Small stubby rhizome → 2x1.
		IngredientData.create(
			&"kencur", "Kencur", "Kaempferia galanga",
			[Vector2i(0, 0), Vector2i(1, 0)],
			Color("bfa77a"),
			[S.BATUK, S.NYERI_SENDI, S.LEMAH],
			2, Vector2(0.34, 0.60),
			"Melegakan pernapasan dan meluruhkan dahak. Meredakan nyeri sendi dan otot."
		),

		# Large rhizome → 2x3.
		IngredientData.create(
			&"temulawak", "Temulawak", "Curcuma xanthorrhiza",
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1),
			 Vector2i(0, 2), Vector2i(1, 2)],
			Color("c47f2b"),
			[S.HATI_LIVER, S.NAFSU_MAKAN, S.PENCERNAAN],
			3, Vector2(0.46, 0.70),
			"Hepatoprotektor: melindungi fungsi hati lewat senyawa xanthorrhizol."
		),

		# A single grain → 1x1. The gap-filler.
		IngredientData.create(
			&"beras", "Beras", "Oryza sativa",
			[Vector2i(0, 0)],
			Color("ede4d3"),
			[S.LEMAH, S.NAFSU_MAKAN],
			0, Vector2(0.0, 0.4),
			"Dasar beras kencur. Menambah stamina dan nafsu makan. Mudah gosong."
		),

		# Curved pod → S/Z shape.
		IngredientData.create(
			&"asam_jawa", "Asam Jawa", "Tamarindus indica",
			[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
			Color("8a5a3c"),
			[S.PENCERNAAN, S.KULIT],
			0, Vector2(0.1, 0.5),
			"Antosianin bersifat analgesik. Pasangan klasik kunyit, menurunkan rasa pahit."
		),

		# Solid moulded block → 2x2.
		IngredientData.create(
			&"gula_jawa", "Gula Jawa", "Arenga pinnata",
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
			Color("6b4423"),
			[],
			0, Vector2(0.0, 0.5),
			"Tidak menyembuhkan, tapi membuat jamu enak diminum. Menaikkan bayaran."
		),

		# ─────────── ADVANCED 4 (day 4+) ───────────

		# Branching leafy stem → T shape.
		IngredientData.create(
			&"sambiloto", "Sambiloto", "Andrographis paniculata",
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
			Color("4f7f3f"),
			[S.DEMAM, S.KULIT, S.HATI_LIVER],
			5, Vector2(0.56, 0.82),
			"Andrographolide: antiinflamasi, antioksidan, antivirus. Bahan utama jamu pahitan."
		),

		IngredientData.create(
			&"temu_ireng", "Temu Ireng", "Curcuma aeruginosa",
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1),
			 Vector2i(0, 2), Vector2i(1, 2)],
			Color("4a3f5a"),
			[S.NAFSU_MAKAN, S.LEMAH, S.WANITA],
			4, Vector2(0.42, 0.68),
			"Bahan jamu cabe puyang. Menambah nafsu makan dan membantu cegah anemia."
		),

		# Heart-shaped leaf → P-hook.
		IngredientData.create(
			&"daun_sirih", "Daun Sirih", "Piper betle",
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1),
			 Vector2i(0, 2)],
			Color("3f7f4f"),
			[S.KULIT, S.LUKA_DALAM, S.WANITA],
			2, Vector2(0.30, 0.56),
			"Antiseptik tradisional. Membersihkan luka dan menjaga kesehatan kewanitaan."
		),

		# Rolled bark quill → 1x3.
		IngredientData.create(
			&"kayu_manis", "Kayu Manis", "Cinnamomum burmannii",
			[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
			Color("8a4f2b"),
			[S.DINGIN, S.PIKIRAN, S.PENCERNAAN],
			1, Vector2(0.60, 0.86),
			"Rempah asli Nusantara. Menghangatkan, menenangkan, membantu pencernaan."
		),
	]
