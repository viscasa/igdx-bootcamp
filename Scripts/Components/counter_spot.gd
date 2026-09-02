class_name CounterSpot extends Node2D

## The bench where a freshly bottled jamu lands. Purely a visual anchor so
## the player knows where to look after pressing SPACE.

const W := 92
const H := 74
const BODY_FONT := preload("res://Assets/Fonts/kelmscottroman/KelmscottRomanNF.ttf")


func _draw() -> void:
	# The bottle itself is the anchor. Keeping this node visually empty avoids
	# a floating technical label between the pan and the finished-brew shelf.
	pass
