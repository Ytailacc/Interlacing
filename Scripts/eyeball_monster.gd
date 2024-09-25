extends CharacterBody2D

enum {
	IDLE,
	CHASE,
	ATTACK,
	TAKE_HIT,
	DEATH,
	SLIDE
}

@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
var damage = 2
var direction
var player
var health = 3
var player_near = false
var timer = true
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
			SLIDE:
				slide_state()


func _ready() -> void:
	state = IDLE


func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	player = Global.player_pos
	
	move_and_slide()


func _on_attack_collition_body_entered(body: Node2D) -> void:
	state = ATTACK
	
func idle_state():
	animPlayer.play("Idle")
	await get_tree().create_timer(1).timeout
	$AttackDirection/AttackCollition/CollisionShape2D.disabled = false
	state = CHASE

func attack_state():
	if player_near == false:
		animPlayer.play("Attack")
		await animPlayer.animation_finished
		$AttackDirection/AttackCollition/CollisionShape2D.disabled = true
		state = IDLE
	else:
		state = SLIDE
	
func chase_state():
	direction = (player - self.position).normalized()
	if direction.x < 0:
		sprite.flip_h = true
		sprite.position.x = -34
		$AttackDirection.rotation_degrees = 180
	elif direction.x > 0:
		sprite.flip_h = false
		sprite.position.x = 34
		$AttackDirection.rotation_degrees = 0
		
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
	
func slide_state():
	if timer == true:
		animPlayer.play("Slide")
		await animPlayer.animation_finished
		timer = false
		if sprite.flip_h == true:
			self.position.x -= 80
		else:
			self.position.x += 80
		state = IDLE
	else:
		state = IDLE
	
func _on_hit_box_area_entered(_area: Area2D) -> void:
	Signals.emit_signal("enemy_attack",damage)


func _on_player_detector_body_entered(body: Node2D) -> void:
	player_near = true
	

func _on_player_detector_body_exited(body: Node2D) -> void:
	player_near = false

func timeOut():
	await get_tree().create_timer(1).timeout
	timer = true


func _on_hurt_box_area_entered(area: Area2D) -> void:
	if state != DEATH and not timer:
		health -= Global.player_damage
		state = TAKE_HIT
	else:
		state = SLIDE
