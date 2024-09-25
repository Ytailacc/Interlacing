extends Node2D

@onready var healthBar = $HealthBar
@onready var damageText = $damageText
@onready var animPlayer = $AnimationText

func _ready() -> void:
	visible = false

func update_heath(new_health,damage):
	healthBar.value = new_health
	damageText.text = str(damage)
	animPlayer.stop()
	animPlayer.play("damage_text")
	visible = true

func start_parameters(max_health):
	healthBar.max_value = max_health
	healthBar.value = max_health
