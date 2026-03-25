extends CanvasLayer

## Main mobile controls container.
## Initializes joystick, hotbar, and touch interactor with references to the player.

@onready var hotbar = $Control/MobileHotbar
@onready var touch_interactor = $TouchInteractor


func setup(player: CharacterBody2D, camera: Camera2D) -> void:
	hotbar.setup(player)
	touch_interactor.setup(player, camera)
