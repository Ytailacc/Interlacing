extends CharacterBody2D

enum {
	IDLE,
	CHASE,
	BLOCK,
	ATTACK,
	DEATH,
}

@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var healthBar = $MobHealth
@onready var attackRange = $AttackDirection/AttackRange/AttackCollision
var damage = 2
var speed = 100
var direction
var player
var health = 50
var state: int = 0:
	set(value):
		state = value
		match state:
			IDLE:
				idle_state()
			CHASE:
				chase_state()
			ATTACK:
				attack_state()
			DEATH:
				death_state()
			BLOCK:
				block_state()

func _ready() -> void:
	healthBar.start_parameters(health)
	state = IDLE
	
func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	player = Global.player_pos
	
	if state == CHASE:
		state = CHASE
		
	
	move_and_slide()
	


func _on_attack_range_body_entered(_body: Node2D) -> void:
	attackRange.set_deferred("disabled",true)
	if state != DEATH:
		state = ATTACK
	
func idle_state():
	animPlayer.play("Idle")
	await get_tree().create_timer(1).timeout
	attackRange.set_deferred("disabled",false)
	state = CHASE

func attack_state():
	velocity.x = 0
	var i = randi_range(1,3)
	match i:
		1:
			animPlayer.play("Attack")
			await animPlayer.animation_finished
		2:
			animPlayer.play("Attack2")
			await animPlayer.animation_finished
		3:
			animPlayer.play("Attack3")
			await animPlayer.animation_finished
	state = IDLE

func chase_state():
	direction = (Global.player_pos - self.position).normalized()
	velocity.x = direction.x * speed
	if direction.x < 0:
		sprite.flip_h = true
		$AttackDirection.rotation_degrees = 180
	elif direction.x > 0:
		sprite.flip_h = false
		$AttackDirection.rotation_degrees = 0

func death_state():
	animPlayer.play("Death")
	await animPlayer.animation_finished
	queue_free()

func block_state():
	if direction.x > 0:
		sprite.flip_h = true
	elif direction.x < 0:
		sprite.flip_h = false
	animPlayer.play("Block")
	await animPlayer.animation_finished
	state = IDLE

func _on_hit_box_area_entered(_area: Area2D) -> void:
	Signals.emit_signal("enemy_attack",damage)

func _on_hurt_box_area_entered(_area: Area2D) -> void:
	if health > 0 and state != DEATH:
		if state == ATTACK:
			health -= Global.player_damage
			healthBar.update_heath(health,Global.player_damage)
		else:
			state = BLOCK
	elif state != DEATH:
		state = DEATH
