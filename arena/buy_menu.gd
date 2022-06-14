extends HBoxContainer

export(NodePath) var company

func _ready():
  company = get_node(company)
  company.connect('credit_changed', self, 'on_credit_changed')
  on_credit_changed(company.capsule_credit)

func on_credit_changed(value):
  for child in get_children():
    if child.has_method('on_credit_changed'):
      child.on_credit_changed(value)
