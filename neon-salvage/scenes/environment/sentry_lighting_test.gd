extends Node2D

@onready var preview: Sprite2D = $ChassisPreview

var surface: CanvasTexture
var saved_normal: Texture2D
var normals_enabled := true


func _ready() -> void:
	surface = preview.texture.duplicate() as CanvasTexture
	preview.texture = surface
	saved_normal = surface.normal_texture
	print("Normal map ON — press N to compare")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.physical_keycode == KEY_N:
				normals_enabled = not normals_enabled
				surface.normal_texture = (
					saved_normal if normals_enabled else null
				)
				print("Normal map ", "ON" if normals_enabled else "OFF")
