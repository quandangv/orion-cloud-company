extends Button

signal buy()

onready var parent = get_parent()
var price:float = 10 setget set_price
var amount:float = 10 setget set_amount

func _pressed():
  if parent.company.request_credit(price) != null:
    buy()
    emit_signal('buy')

func buy():
  pass

func set_price(value):
  price = value
  if $price:
    $price.text = str(value)
    yield(get_tree(), 'idle_frame')
    on_credit_changed(null)

func set_amount(value):
  amount = value
  if $amount:
    $amount.text = str(value)

func _ready():
  if get_node_or_null('amount'):
    amount = int($amount.text)
  price = int($price.text)

func on_credit_changed(_v):
  disabled = parent.company.capsule_credit < price
