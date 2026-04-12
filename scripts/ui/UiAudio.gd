extends Node

const UI_BUTTON_CLICK_SFX := preload("res://assets/audio/sfx/ui/battle_scene.mp3")


func should_play_for_button(button: BaseButton) -> bool:
	if button == null:
		return false
	return button.text != "返回"


func play_ui_click() -> void:
	if UI_BUTTON_CLICK_SFX == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = UI_BUTTON_CLICK_SFX
	player.volume_db = -20.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
