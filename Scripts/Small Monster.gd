extends CharacterBody2D

enum {
	IDLE,
	CHASE,
	ATTACK,
	TAKE_HIT,
	DEATH
}

@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var healthBar = $MobHealth
@onready var damageCollition_1 = $DamageBox/HitBox/CollisionShape2D
@onready var damageCollition_2 = $DamageBox/HitBox/CollisionShape2D2
@export var change_position = [5,-5]
var damage = 1
var direction
var player
var health = 6
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
			TAKE_HIT:
				take_hit_state()
			DEATH:
				death_state()

func _ready() -> void:
	healthBar.start_parameters(health)
	state = IDLE
	
func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if state == CHASE:
		chase_state()
	 
	player = Global.player_pos
	
	move_and_slide()


func _on_attack_range_body_entered(_body: Node2D) -> void:
	state = ATTACK
	
func idle_state():
	animPlayer.play("Idle")
	await get_tree().create_timer(1).timeout
	$AttackDirection/AttackRange/AttackCollision.disabled = false
	$AttackDirection/AttackRange/AttackCollision2.disabled = false
	state = CHASE

func attack_state():
	velocity.x = 0
	animPlayer.play("Attack")
	await animPlayer.animation_finished
	$AttackDirection/AttackRange/AttackCollision.disabled = true
	$AttackDirection/AttackRange/AttackCollision2.disabled = true
	state = IDLE

func chase_state():
	direction = (player - self.position).normalized()
	if direction.x < 0:
		sprite.flip_h = true
		sprite.position.x = change_position[1]
	elif direction.x > 0:
		sprite.flip_h = false
		sprite.position.x = change_position[0]

func take_hit_state():
	if health > 0 and state != DEATH:
		animPlayer.play("Take_Hit")
		await animPlayer.animation_finished
		state = IDLE
	else:
		state = DEATH

func death_state():
	animPlayer.play("Death")
	await animPlayer.animation_finished
	queue_free()


func _on_hit_box_area_entered(_area: Area2D) -> void:
	Signals.emit_signal("enemy_attack",damage)
	


func _on_hurt_box_area_entered(_area: Area2D) -> void:
	if state != DEATH:
		health -= Global.player_damage
		healthBar.update_heath(health,Global.player_damage)
		state = TAKE_HIT

func _check_flip_h():
	if sprite.flip_h:
		damageCollition_2.disabled = false
		await  get_tree().create_timer(0.1).timeout
		damageCollition_2.disabled = true
		await  get_tree().create_timer(0.3).timeout
		damageCollition_1.disabled = false
		await  get_tree().create_timer(0.1).timeout
		damageCollition_1.disabled = true
	else:
		damageCollition_1.disabled = false
		await  get_tree().create_timer(0.1).timeout
		damageCollition_1.disabled = true
		await  get_tree().create_timer(0.3).timeout
		damageCollition_2.disabled = false
		await  get_tree().create_timer(0.1).timeout
		damageCollition_2.disabled = true
