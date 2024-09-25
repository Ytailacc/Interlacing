extends CharacterBody2D

enum {
	MOVE,
	ATTACK,
	ATTACK2,
	ATTACK3,
	SLIDE,
	DEATH,
	TAKE_HIT
}

var SPEED = 200
const JUMP_VELOCITY = -400.0
var state = MOVE
@onready var anim = $AnimatedSprite2D
@onready var  animPlayer = $AnimationPlayer
@onready var animDamage = $healthText/DamageAnimation
@onready var textDamage = $healthText/DamageText
var health = 10
var combo = false
var combo2 = false
var damage_current
var damage_basic = 2
var damage_multiplier = 1

func _ready() -> void:
	Signals.connect("enemy_attack",Callable(self,"_on_damage_recived"))
	textDamage.visible = false

func _physics_process(delta: float) -> void:
	match state:
		MOVE:
			move_state()
		ATTACK:
			attack_state()
		ATTACK2:
			attack2_state()
		ATTACK3: 
			attack3_state()
		SLIDE:
			slide_state()
		TAKE_HIT:
			take_hit_state()
		DEATH:
			death_state()
	
	Global.player_damage = damage_basic * damage_multiplier
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	
	move_and_slide()
	
	Global.player_pos = position
	
func move_state():
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		if velocity.y == 0:
			animPlayer.play("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			animPlayer.play("Idle")
		
	if direction == 1:
		anim.flip_h = false
		$DamageBox.rotation_degrees = 0
	elif direction == -1:
		anim.flip_h = true
		$DamageBox.rotation_degrees = 180
		
	if velocity.y > 0:
		animPlayer.play("Fall")
	elif velocity.y < 0:
		animPlayer.play("Jump")
	
	if Input.is_action_pressed("slide"):
		if velocity.x != 0:
			state = SLIDE
	
	if Input.is_action_pressed("attack"):
		state = ATTACK
		
func slide_state():
	animPlayer.play("Slide")
	await animPlayer.animation_finished
	state = MOVE

func attack_state():
	damage_multiplier = 1
	if Input.is_action_just_pressed("attack") and combo == true:
		state = ATTACK2
	velocity.x = 0
	animPlayer.play("Attack")
	await animPlayer.animation_finished
	state = MOVE

func attack2_state():
	damage_multiplier = 1.2
	if Input.is_action_just_pressed("attack") and combo2 == true:
		state = ATTACK3
	animPlayer.play("Attack2")
	await animPlayer.animation_finished
	state = MOVE
	
func attack3_state():
	damage_multiplier = 1.5
	animPlayer.play("Attack3")
	await animPlayer.animation_finished
	state = MOVE
	
func combo1():
	combo = true
	await animPlayer.animation_finished
	combo = false
	
func combo_2():
	combo2 = true
	await animPlayer.animation_finished
	combo2 = false
	
func take_hit_state():
	if health <= 0:
		state = DEATH
	velocity.x = 0
	animPlayer.play("Take_Hit")
	await animPlayer.animation_finished
	state = MOVE
	
func _on_damage_recived(enemy_damage):
	if state != DEATH and state != SLIDE:
		state = TAKE_HIT
		health -= enemy_damage
		textDamage.visible = true
		textDamage.text = str(enemy_damage)
		animDamage.stop()
		animDamage.play("damage_text")
		print(health)

func death_state():
	velocity.x = 0
	health = 0
	animPlayer.play("Death")
	await animPlayer.animation_finished
	queue_free()
	#get_tree().change_scene_to_file("")
