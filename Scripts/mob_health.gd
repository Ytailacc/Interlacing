extends Node2D

@onready var healthBar = $HealthBar
@onready var damageText = $damageText

func _ready() -> void:
	pass

func update_heath(new_health,damage):
	healthBar.value = new_health

func start_parameters(max_health):
	healthBar.max_value = max_health
	healthBar.value = max_health
