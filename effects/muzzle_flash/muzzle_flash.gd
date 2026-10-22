class_name MuzzleFlash
extends Node3D

@export_group("Particles")
@export var particle_process_material: ParticleProcessMaterial
@export var particle_mesh: Mesh
@export var muzzle_flash_scale := 0.2

@onready var particles: GPUParticles3D = $Particles


func _ready() -> void:
	particles.one_shot = true
	particles.emitting = false

	if particle_process_material:
		particles.process_material = particle_process_material
	if particle_mesh:
		particles.draw_pass_1 = particle_mesh

	particles.scale = Vector3.ONE * muzzle_flash_scale


func flash() -> void:
	particles.restart()
