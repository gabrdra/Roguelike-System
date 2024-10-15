class_name SimpleDeque extends Node
var first:Element
var last:Element
var curr:Element #should be used only for the iterator
#TODO: add the ability to insert an element on the front, and add the ability to remove the last x elements
#create a reference to the previous element in the Element class in order to do that in linear time
func insert_back(value) -> void:
	var new_element = Element.new(value, null, last)
	if(first==null):
		first = new_element
		last = new_element
	else:
		last.next = new_element
	last = new_element
	
func insert_deque_back(deque:SimpleDeque)  -> void:
	if deque.is_empty():
		return
	if is_empty():
		first = deque.first
	else:
		last.next = deque.first
	last = deque.last
	
func pop_back():
	if last == null:
		return null
	var return_element = last
	last = return_element.previous
	if last == null:
		first = null
	return return_element.value

func pop_front():
	if first == null:
		return null
	var return_element = first
	first = first.next
	if first == null:
		last = null
	return return_element.value

func insert_front(value) -> void:
	if first == null:
		insert_back(value)
		return
	var new_element = Element.new(value, first)
	first.previous = new_element
	first = new_element

func erase_elements_from_back(amount:int) -> void:
	for i in range(amount):
		if last == null:
			printerr("could only erase "+str(i+1)+" elements from the deque")
			return
		pop_back()

func is_empty() -> bool:
	return first==null

#functions needed for the iterator to work
#The iterator doesn't work with nested loops over the same deque!
func _keep_iterating() -> bool:
	return curr != null

func _iter_init(arg) -> bool:
	curr = first
	return _keep_iterating()

func _iter_next(arg) -> bool:
	curr = curr.next
	return _keep_iterating()

func _iter_get(arg):
	return curr.value

#end of iterator functions

class Element:
	var value
	var next:Element
	var previous:Element
	func _init(_value, _next = null, _previous = null):
		value = _value
		next = _next
		previous = _previous
