extends Control


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(Global.INTRO)


func _on_settings_pressed() -> void:
	$Popup.show()


func _on_how_to_play_pressed() -> void:
	$"How To Play".show()
