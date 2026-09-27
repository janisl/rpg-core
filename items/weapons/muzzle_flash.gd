class_name MuzzleFlash
extends Node3D

@export_group("Particles")
@export var particle_process_material: ParticleProcessMaterial
@export var particle_mesh: Mesh
@export var muzzle_flash_scale := 0.2

@export_group("Light")
@export var light_color := Color(1.0, 0.8, 0.4)
@export var light_energy := 10.0
@export var light_duration := 0.05

@onready var particles: GPUParticles3D = $Particles
@onready var light: OmniLight3D = $Light

var _light_tween: Tween


func _ready() -> void:
	particles.one_shot = true
	particles.emitting = false
	light.light_energy = 0.0

	if particle_process_material:
		particles.process_material = particle_process_material
	if particle_mesh:
		particles.draw_pass_1 = particle_mesh

	particles.scale = Vector3.ONE * muzzle_flash_scale


func flash() -> void:
	particles.restart()

	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()
	light.light_color = light_color
	light.light_energy = light_energy
	_light_tween = create_tween().bind_node(self)
	_light_tween.tween_property(light, "light_energy", 0.0, light_duration)


func _exit_tree() -> void:
	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()
