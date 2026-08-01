extends Node

## Autoload: switches between the two rooms of the shop.
##
## Both rooms are separate scenes so each gets a full screen to breathe in —
## the counter can show long complaints and potency bars, the kitchen can
## show the pot, the shelf and the tools without either being cramped.
## GameState keeps the shift running underneath, so this really is just
## walking through a doorway.

enum Room { KASIR, DAPUR }

signal room_changed(room: Room)

const PATHS := {
	Room.KASIR: "res://Scenes/Game/kasir.tscn",
	Room.DAPUR: "res://Scenes/Game/dapur.tscn",
}

const NAMES := {
	Room.KASIR: "KASIR",
	Room.DAPUR: "DAPUR",
}

var current: Room = Room.KASIR


func go(room: Room) -> void:
	if room == current and get_tree().current_scene != null:
		return
	current = room
	get_tree().change_scene_to_file(PATHS[room])
	room_changed.emit(room)


func toggle() -> void:
	go(Room.DAPUR if current == Room.KASIR else Room.KASIR)


static func display_name(room: Room) -> String:
	return NAMES.get(room, "?")


func other_name() -> String:
	return NAMES[Room.DAPUR] if current == Room.KASIR else NAMES[Room.KASIR]
