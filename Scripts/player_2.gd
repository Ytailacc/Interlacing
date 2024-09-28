extends CharacterBody2D


var SPEED = 150
const JUMP_VELOCITY = -400.0
var state = MOVE
var health = 15
var damage = 4
@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var animDamage = $healthText/DamageAnimation
@onready var textDamage = $healthText/DamageText

enum {
	MOVE,
	BLOCK,
	DEATH,
	TAKE_HIT,
	ATTACK
}

func _ready() -> void:
	Signals.connect("enemy_attack",Callable(self,"_on_damage_recived"))
	Global.player_health = health
	textDamage.visible = false

func _physics_process(delta: float) -> void:
	match state:
		MOVE:
			move_state()
		BLOCK:
			block_state()
		TAKE_HIT:
			take_hit_state()
		DEATH:
			death_state()
		ATTACK:
			attack_state()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	Global.player_pos = position
	Global.player_damage = damage
	
func move_state():
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		if velocity.y == 0:
			animPlayer.play("Run")
			sprite.scale.x = 0.013
			sprite.scale.y = 0.013
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			animPlayer.play("Idle")
			sprite.scale.x = 0.013
			sprite.scale.y = 0.013
	
	if direction == 1:
		sprite.flip_h = true
		$DamageBox.rotation_degrees = 0
	elif direction == -1:
		sprite.flip_h = false
		$DamageBox.rotation_degrees = 180
		
	if velocity.y > 0:
		animPlayer.play("Fall")
		sprite.scale.x = 0.02
		sprite.scale.y = 0.02
	elif velocity.y < 0:
		animPlayer.play("Jump")
		sprite.scale.x = 0.02
		sprite.scale.y = 0.02
	
	if Input.is_action_pressed("slide"):
		if velocity.y == 0:
			state = BLOCK
	
	if Input.is_action_pressed("attack"):
		state = ATTACK
			
func block_state():
	velocity.x = 0
	SPEED = 0
	animPlayer.play("Block")
	if Input.is_action_just_released("slide"):
		SPEED = 200
		state = MOVE
		
func take_hit_state():
	velocity.x = 0
	if health <= 0:
		state = DEATH
	SPEED = 0
	animPlayer.play("Take_Hit")
	await animPlayer.animation_finished
	SPEED = 200
	state = MOVE
	
func death_state():
	velocity.x = 0
	SPEED = 0
	health = 0
	animPlayer.play("Death")
	await animPlayer.animation_finished
	queue_free()

func attack_state():
	velocity.x = 0
	SPEED = 0
	sprite.scale.x = 0.018
	sprite.scale.y = 0.018
	animPlayer.play("Punch")
	await animPlayer.animation_finished
	SPEED = 150
	state = MOVE
	
func _on_damage_recived(enemy_damage):
	if state != DEATH and state != BLOCK:
		state = TAKE_HIT
		health -= enemy_damage
		Signals.emit_signal("player_health",health)
		textDamage.visible = true
		textDamage.text = str(enemy_damage)
		animDamage.stop()
		animDamage.play("damage_text")
		print(health)

func change_scene():
	if Global.open_scene:
		get_tree().change_scene_to_file(Global.open_scene.scene_file_path)
	else:
		get_tree().change_scene_to_file("res://Scenes/menu.tscn")
