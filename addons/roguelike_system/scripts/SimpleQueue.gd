class_name SimpleQueue extends Node
var first:Element
var last:Element
func insert(element) -> void:
	var new_element = Element.new(element)
	if(first==null):
		first = new_element
		last = new_element
	else:
		last.next = new_element
	last = new_element
	
func insert_queue(queue:SimpleQueue)  -> void:
	if queue.is_empty():
		return
	if is_empty():
		first = queue.first
	else:
		last.next = queue.first
	last = queue.last
	
func pop_front():
	if first == null:
		return null
	var return_element = first
	first = first.next
	return return_element.value

func is_empty() -> bool:
	return first==null
class Element:
	var value
	var next:Element
	func _init(_value):
		value = _value
