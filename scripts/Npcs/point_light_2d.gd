extends PointLight2D



func _process(_delta: float) -> void:

	var rot=rad_to_deg(self.get_parent().rotation)
	if rot<=1 and rot>=-1:
		self.get_parent().position.y=9.48
	else: 
		self.get_parent().position.y=0
	
