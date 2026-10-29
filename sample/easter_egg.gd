extends CanvasLayer
## Easter egg: a 3D head wearing a generated smiley flies around over the
## sample UI. Tap anywhere to dismiss. Drop an image at
## res://easter_egg/face.png to put that on the head instead.

const FACE_PATH := "res://easter_egg/face.png"
const HEAD_RADIUS := 0.5

var _head: Node3D
var _time := 0.0


func _ready() -> void:
	layer = 100

	var container := SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.gui_input.connect(_on_gui_input)
	add_child(container)

	var viewport := SubViewport.new()
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	container.add_child(viewport)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 4)
	viewport.add_child(camera)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	viewport.add_child(sun)

	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	viewport.add_child(environment)

	_head = _build_head()
	viewport.add_child(_head)


func _process(delta: float) -> void:
	_time += delta
	# Lissajous flight path that stays inside a portrait screen, with a wobble
	# that keeps the face mostly toward the camera and a full spin every few
	# seconds.
	_head.position = Vector3(sin(_time * 1.3) * 0.55, sin(_time * 1.9) * 1.4, sin(_time * 0.7) * 0.6 - 0.4)
	var spin := smoothstep(0.0, 1.0, clampf(fmod(_time, 6.0) - 5.0, 0.0, 1.0)) * TAU
	_head.rotation = Vector3(sin(_time * 1.1) * 0.3, sin(_time * 0.9) * 0.6 + spin, sin(_time * 1.7) * 0.25)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()


func _build_head() -> Node3D:
	var head := Node3D.new()

	# Skin-colored sphere; the face itself is a texture on a curved shell over
	# the front half, so it wraps around the head instead of sitting flat.
	var skull := MeshInstance3D.new()
	var skull_mesh := SphereMesh.new()
	skull_mesh.radius = HEAD_RADIUS
	skull_mesh.height = HEAD_RADIUS * 2.0
	skull.mesh = skull_mesh
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.93, 0.76, 0.64)
	skull.material_override = skin
	head.add_child(skull)

	var face := MeshInstance3D.new()
	face.mesh = _build_face_shell(HEAD_RADIUS * 1.01, deg_to_rad(140.0), deg_to_rad(130.0), 24)
	var face_material := StandardMaterial3D.new()
	face_material.albedo_texture = _load_face_texture()
	face_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	face_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	face.material_override = face_material
	head.add_child(face)

	return head


## Front-facing spherical patch (+Z), spanning [param width] radians around
## and [param height] radians up/down, with the image mapped across it.
func _build_face_shell(radius: float, width: float, height: float, segments: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in segments + 1:
		var v := float(row) / segments
		var lat := (0.5 - v) * height
		for col in segments + 1:
			var u := float(col) / segments
			var lon := (u - 0.5) * width
			var normal := Vector3(sin(lon) * cos(lat), sin(lat), cos(lon) * cos(lat))
			st.set_normal(normal)
			st.set_uv(Vector2(u, v))
			st.add_vertex(normal * radius)
	for row in segments:
		for col in segments:
			var i := row * (segments + 1) + col
			var below := i + segments + 1
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(below)
			st.add_index(i + 1)
			st.add_index(below + 1)
			st.add_index(below)
	return st.commit()


func _load_face_texture() -> Texture2D:
	if ResourceLoader.exists(FACE_PATH):
		return load(FACE_PATH)
	return ImageTexture.create_from_image(_smiley())


func _smiley() -> Image:
	var size := 256
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	for y in size:
		for x in size:
			var p := Vector2(x, y)
			var color := Color(1.0, 0.85, 0.2)
			var mouth := p.distance_to(center + Vector2(0, -10))
			if p.distance_to(center + Vector2(-45, -35)) < 18 or p.distance_to(center + Vector2(45, -35)) < 18:
				color = Color.BLACK
			elif mouth > 70 and mouth < 84 and y > center.y + 10:
				color = Color.BLACK
			image.set_pixel(x, y, color)
	return image
