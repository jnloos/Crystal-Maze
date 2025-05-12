extends MultiMeshInstance3D

@export var width: int = 10
@export var height: int = 10
@export var cell_size: Vector3 = Vector3(1, 0, 1)

func _ready():
	var mm = multimesh
	mm.instance_count = width * height
	for x in width:
		for z in height:
			var i = x * height + z
			# Position im Grid
			var pos = Vector3(
				x * cell_size.x,
				0,
				z * cell_size.z
			)
			# Transform: Ort + (optional) Drehung/Skalierung
			var xf = Transform3D.IDENTITY
			xf.origin = pos
			mm.set_instance_transform(i, xf)
