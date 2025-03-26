extends Control
@onready var win: NinePatchRect = $Win
@onready var lose: NinePatchRect = $Lose

func _ready() -> void:
	win.hide()
	lose.hide()
	if Global.win:
		win.show()
	else:
		lose.show()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.MENU)
