class_name KualiCell extends Node2D

@onready var body: ColorRect = $Body
@onready var border: Panel = $Border
@onready var residue_art: Node2D = $Residue
@onready var hover: ColorRect = $Hover


func set_state(is_residue: bool, hover_color: Color = Color.TRANSPARENT) -> void:
	body.color = Color("32170f") if is_residue else Color("6a4935")
	residue_art.visible = is_residue
	hover.visible = hover_color.a > 0.0
	if hover.visible:
		var shader_material := hover.material as ShaderMaterial
		if shader_material != null:
			shader_material.set_shader_parameter("valid",
				1.0 if hover_color.g > hover_color.r else 0.0)
