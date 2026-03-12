extends StaticBody2D

const apple_texture = preload("res://graphics/plants/apple.png")
const MAX_WOOD := 4 # BUG FIX: cap total wood from one tree to prevent infinite wood exploit
var chopped := false # BUG FIX: tracks if tree is already chopped (stump state)
var wood_given := 0 # BUG FIX: tracks total wood given from this tree
var days_since_chopped := 0 # BUG FIX: counter for tree regrowth (grows back after 3 days)
const REGROW_DAYS := 3 # BUG FIX: number of days before a chopped tree regrows
var original_shape: Shape2D
var original_shape_pos_y: float
var health := 3:
	set(value):
		health = value
		if health <= 0 and not chopped:
			chopped = true
			$FlashSprite2D.hide()
			$Stump.show()
			# BUG FIX: give wood capped at MAX_WOOD total per tree lifecycle
			var wood_amount = clampi(randi_range(2, 4), 0, MAX_WOOD - wood_given)
			wood_given += wood_amount
			if wood_amount > 0:
				Data.change_item(Enum.Item.WOOD, wood_amount)
			var shape = RectangleShape2D.new()
			shape.size = Vector2(12,6)
			$CollisionShape2D.shape = shape
			$CollisionShape2D.position.y = 8


func _ready() -> void:
	original_shape = $CollisionShape2D.shape.duplicate()
	original_shape_pos_y = $CollisionShape2D.position.y
	$FlashSprite2D.frame = [0,1].pick_random()
	create_apples(randi_range(0,3))


func hit(tool: Enum.Tool):
	# BUG FIX: prevent hitting a chopped tree (stump) to stop infinite wood
	if tool == Enum.Tool.AXE and not chopped:
		$FlashSprite2D.flash()
		get_apple()
		health -= 1


func create_apples(num: int):
	var apple_markers = $AppleSpawnPositions.get_children().duplicate(true)
	for i in num:
		var pos_marker = apple_markers.pop_at(randi_range(0, apple_markers.size() - 1))
		var sprite = Sprite2D.new()
		sprite.texture = apple_texture
		$Apples.add_child(sprite)
		sprite.position = pos_marker.position


func get_apple():
	if $Apples.get_children():
		$Apples.get_children().pick_random().queue_free()
		Data.change_item(Enum.Item.APPLE)


func reset():
	if chopped:
		# BUG FIX: tree regrows after REGROW_DAYS days
		days_since_chopped += 1
		if days_since_chopped >= REGROW_DAYS:
			chopped = false
			days_since_chopped = 0
			wood_given = 0
			health = 3
			$FlashSprite2D.show()
			$FlashSprite2D.frame = [0,1].pick_random()
			$Stump.hide()
			$CollisionShape2D.shape = original_shape.duplicate()
			$CollisionShape2D.position.y = original_shape_pos_y
			for apple in $Apples.get_children():
				apple.queue_free()
			create_apples(randi_range(0,3))
	else:
		# Normal daily reset: refresh apples
		for apple in $Apples.get_children():
			apple.queue_free()
		create_apples(randi_range(0,3))
