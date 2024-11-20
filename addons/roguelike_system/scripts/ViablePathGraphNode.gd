class_name ViablePathGraphNode extends Resource

var id:int
var connection_pair_id:int
var children:Array
var children_frequency:Array
var parents:Dictionary
func _init(_id:int, _connection_pair_id:int, _children:Array = [], _children_frequency:Array = [], _parents:Dictionary = {}):
	id = _id
	connection_pair_id = _connection_pair_id
	children = _children
	children_frequency = _children_frequency
	parents = _parents

func add_child(child_id:int, child_connection_pair_id:int) -> ViablePathGraphNode:
	#adds a child or increase the frequency if it was already a child, return the child node
	for curr_child_id in range(children.size()):
		if children[curr_child_id].connection_pair_id == child_connection_pair_id:
			children_frequency[curr_child_id]+=1
			return children[curr_child_id]
	var new_child := ViablePathGraphNode.new(child_id, child_connection_pair_id,[],[],{connection_pair_id:self})
	children.append(new_child)
	children_frequency.append(1)
	return new_child
