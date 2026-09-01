@tool
class_name CustomerAppearance extends Node2D

## Each visual category owns exactly one Sprite2D. A randomized variant applies
## both its texture and its authored position, so different canvas sizes align.

const BACK_HAIR_OPTIONS: Array[Texture2D] = [
	preload("res://Assets/Characters/Back Hair/backhair_1.png"),
	preload("res://Assets/Characters/Back Hair/backhair_2.png"),
	preload("res://Assets/Characters/Back Hair/backhair_3.png"),
	preload("res://Assets/Characters/Back Hair/backhair_4.png"),
	preload("res://Assets/Characters/Back Hair/backhair_5.png"),
	preload("res://Assets/Characters/Back Hair/backhair_6.png"),
	preload("res://Assets/Characters/Back Hair/backhair_7.png"),
]

const BACK_HAIR_POSITIONS: Array[Vector2] = [
	Vector2(-3, -39),
	Vector2(-3, -39),
	Vector2(-3, -39),
	Vector2(-3, -39),
	Vector2(-3, -39),
	Vector2(-3, -39),
	Vector2(-26, -103),
]

const NOSE_OPTIONS: Array[Texture2D] = [
	preload("res://Assets/Characters/Nose/nose_1.png"),
	preload("res://Assets/Characters/Nose/nose_2.png"),
]

const EYEBROW_OPTIONS: Array[Texture2D] = [
	preload("res://Assets/Characters/Eyebrows/eyebrows_angry.png"),
	preload("res://Assets/Characters/Eyebrows/eyebrows_normal.png"),
	preload("res://Assets/Characters/Eyebrows/eyebrows_worry.png"),
]

const EYE_OPTIONS: Array[Texture2D] = [
	preload("res://Assets/Characters/Eyes/eyes_1.png"),
	preload("res://Assets/Characters/Eyes/eyes_2.png"),
	preload("res://Assets/Characters/Eyes/eyes_3.png"),
	preload("res://Assets/Characters/Eyes/eyes_4.png"),
]

const MOUTH_OPTIONS: Array[Texture2D] = [
	preload("res://Assets/Characters/Mouth/mouth_cat.png"),
	preload("res://Assets/Characters/Mouth/mouth_catopen.png"),
	preload("res://Assets/Characters/Mouth/mouth_frown.png"),
	preload("res://Assets/Characters/Mouth/mouth_grin.png"),
	preload("res://Assets/Characters/Mouth/mouth_smile.png"),
	preload("res://Assets/Characters/Mouth/mouth_uncomfy.png"),
]

const FRONT_HAIR_OPTIONS: Array[Texture2D] = [
	preload("res://Assets/Characters/Front Hair/fronthair_1.png"),
	preload("res://Assets/Characters/Front Hair/fronthair_2.png"),
	preload("res://Assets/Characters/Front Hair/fronthair_3.png"),
	preload("res://Assets/Characters/Front Hair/fronthair_4.png"),
	preload("res://Assets/Characters/Front Hair/fronthair_5.png"),
]

const FRONT_HAIR_POSITIONS: Array[Vector2] = [
	Vector2(-16, -252),
	Vector2(-16, -252),
	Vector2(-16, -156),
	Vector2(-16, -252),
	Vector2(-12, -262),
]

const HAIR_DECOR_OPTIONS: Array[Texture2D] = [
	preload("res://Assets/Characters/Hair decor/hairdecor_bunga.png"),
	preload("res://Assets/Characters/Hair decor/hairdecor_jepit.png"),
]

const HAIR_DECOR_POSITIONS: Array[Vector2] = [
	Vector2(101, -209),
	Vector2(-7, -223),
]

const JEWELRY_OPTIONS: Array[Texture2D] = [
	preload("res://Assets/Characters/Clothes/Jewelry/jewelry_1.png"),
	preload("res://Assets/Characters/Clothes/Jewelry/jewelry_2.png"),
]

const JEWELRY_POSITIONS: Array[Vector2] = [
	Vector2(-17, 193),
	Vector2(-17, 193),
]

const FRONT_CLOTHES_OPTIONS: Array[Texture2D] = [
	preload("res://Assets/Characters/Clothes/Front/frontclothes_1.png"),
	preload("res://Assets/Characters/Clothes/Front/frontclothes_2.png"),
	preload("res://Assets/Characters/Clothes/Front/frontclothes_3.png"),
]

@export_group("Random Appearance")
@export var randomize_on_ready: bool = true
## Use 0 for a fresh random appearance. Any other value is reproducible.
@export var appearance_seed: int = 0
## Check this in the editor to generate a new preview, then it resets itself.
@export var randomize_preview: bool = false:
	set(value):
		randomize_preview = value
		if value and Engine.is_editor_hint():
			call_deferred("_consume_preview_toggle")

@onready var back_hair: Sprite2D = $BackHair
@onready var nose: Sprite2D = $Nose
@onready var eyebrows: Sprite2D = $Eyebrows
@onready var eyes: Sprite2D = $Eyes
@onready var mouth: Sprite2D = $Mouth
@onready var front_hair: Sprite2D = $FrontHair
@onready var jewelry: Sprite2D = $Jewelry
@onready var front_clothes: Sprite2D = $FrontClothes
@onready var hair_decor: Sprite2D = $HairDecor


func _ready() -> void:
	if not Engine.is_editor_hint() and randomize_on_ready:
		randomize_appearance()


func _consume_preview_toggle() -> void:
	if not is_node_ready():
		return
	randomize_appearance()
	randomize_preview = false
	notify_property_list_changed()


func randomize_appearance() -> void:
	var rng := RandomNumberGenerator.new()
	if appearance_seed == 0:
		rng.randomize()
	else:
		rng.seed = appearance_seed

	_apply_variant(back_hair, BACK_HAIR_OPTIONS, BACK_HAIR_POSITIONS, rng)
	nose.texture = _pick(NOSE_OPTIONS, rng)
	eyebrows.texture = _pick(EYEBROW_OPTIONS, rng)
	eyes.texture = _pick(EYE_OPTIONS, rng)
	mouth.texture = _pick(MOUTH_OPTIONS, rng)
	_apply_variant(front_hair, FRONT_HAIR_OPTIONS, FRONT_HAIR_POSITIONS, rng)
	_apply_optional_variant(jewelry, JEWELRY_OPTIONS, JEWELRY_POSITIONS, rng)
	front_clothes.texture = _pick(FRONT_CLOTHES_OPTIONS, rng)
	_apply_optional_variant(hair_decor, HAIR_DECOR_OPTIONS, HAIR_DECOR_POSITIONS, rng)


func _apply_variant(sprite: Sprite2D, textures: Array[Texture2D],
		positions: Array[Vector2], rng: RandomNumberGenerator) -> void:
	assert(textures.size() == positions.size())
	var variant := rng.randi_range(0, textures.size() - 1)
	sprite.texture = textures[variant]
	sprite.position = positions[variant]
	sprite.visible = true


func _apply_optional_variant(sprite: Sprite2D, textures: Array[Texture2D],
		positions: Array[Vector2], rng: RandomNumberGenerator) -> void:
	assert(textures.size() == positions.size())
	# The extra index represents "no accessory", giving each outcome the
	# same probability as an individual artwork variant.
	var variant := rng.randi_range(0, textures.size())
	if variant == textures.size():
		sprite.visible = false
		return
	sprite.texture = textures[variant]
	sprite.position = positions[variant]
	sprite.visible = true


func _pick(options: Array[Texture2D], rng: RandomNumberGenerator) -> Texture2D:
	return options[rng.randi_range(0, options.size() - 1)]
