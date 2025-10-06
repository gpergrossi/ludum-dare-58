@tool
class_name UpgradeUI extends PanelContainer

@onready var icon: TextureRect = %Icon
@onready var label_name: Label = %LabelName
@onready var label_price: Label = %LabelPrice
@onready var button: Button = %Button

var shop: PopupShop
var upgrade: StringName = "Uninitialized"
var displayed: StringName = ""

var unlocked := false
var purchased := false
var price := 100
var opacity := 1.0


func _process(delta: float) -> void:
	if shop == null: return
	unlocked = shop.upgrades.is_upgrade_unlocked(upgrade)
	purchased = shop.upgrades.is_upgrade_purchased(upgrade)
	price = shop.upgrades.get_upgrade_cost(upgrade)
	
	label_name.text = upgrade
	label_price.text = "Price: " + str(roundi(price * LabelDust.display_scale))
	
	if purchased:
		button.text = "Bought"
		button.disabled = true
		opacity = move_toward(opacity, 0.0, delta * 0.5)
		modulate = Color(Color.WHITE, opacity)
		visible = (opacity != 0.0)
	else:
		button.text = "Buy"
		button.disabled = shop.player.stored_dust < price
		opacity = 1.0
		modulate = Color(Color.WHITE, opacity)
		visible = true
	
	if not unlocked:
		visible = false


func _on_button_pressed() -> void:
	if unlocked and not purchased and price < shop.player.stored_dust:
		print("Bought upgrade: " + upgrade)
		shop.player.stored_dust -= price
		shop.upgrades.grant_upgrade(upgrade)
