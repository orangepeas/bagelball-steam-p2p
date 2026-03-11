extends OptionButton

func select_map():
	match self.selected:
		1:
			global.map = global.Map.warehouse
		2:
			global.map = global.Map.cylinder
		4:
			global.map = global.Map.bagel
		5:
			global.map = global.Map.dome
		7:
			global.map = global.Map.sumo
		8:
			global.map = global.Map.sumo2
		10:
			global.map = global.Map.sisyphus
