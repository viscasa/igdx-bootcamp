class_name KualiCell extends Node2D

@onready var body: ColorRect = $Body
@onready var border: Panel = $Border
@onready var residue_art: Node2D = $Residue
@onready var hover: ColorRect = $Hover


func set_state(is_residue: bool, hover_color: Color = Color.TRANSPARENT) -> void:
	body.color = Color("6b3f2b") if is_residue else Color("6a4935")
	residue_art.visible = is_residue
	hover.visible = hover_color.a > 0.0
	hover.color = hover_color
