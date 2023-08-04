--[=[
	An entry in a LinkedList.

	Allows removing this entry from the list. This is a constant time operation.

	.remove () -> ()

	@interface Entry<T>
	@within LinkedList
]=]
export type Entry<T> = {
	remove: () -> (),
}

type UnknownNode = {
	value: unknown,
	entry: Entry<unknown>,
	next: UnknownNode?,
	prev: UnknownNode?,
}

type Node<T> = {
	value: T,
	entry: Entry<T>,
	next: UnknownNode?,
	prev: UnknownNode?,
}

--[=[
	A doubly-linked list.

	Easily inserts and deletes arbitrarily without reordering. A reference to the
	entry to insert or delete at is required. A reference to the front and back of
	the list always exist. When inserting new entries, entry references are
	provided for convenient removal.

	@class LinkedList
	@ignore
]=]
local LinkedList = {}
LinkedList.__index = LinkedList

--[=[
	Creates a new LinkedList.

	@within LinkedList
]=]
function LinkedList.new()
	local self = setmetatable({}, LinkedList)
	return self
end

--[=[
	Pushes a new entry to the back of the List.

	@within LinkedList
]=]
function LinkedList:Push<T>(value: T): Entry<T>
	local node: Node<T>?
	local entry = {
		remove = function()
			if not node then
				error("Attempted to remove node from LinkedList more than once.")
			end

			if node.prev then
				node.prev.next = node.next
			else
				self.front = node.next
			end

			if node.next then
				node.next.prev = node.prev
			else
				self.back = node.prev
			end

			node = nil
		end,
	}

	node = {
		value = value,
		prev = self.back,
		entry = entry,
	}

	if self.back then
		self.back.next = node
	else
		self.front = node
	end
	self.back = node

	return entry
end

--[=[
	Shifts an entry off of the front of the List.

	@within LinkedList
]=]
function LinkedList:Shift(): unknown
	local node = self.front
	if node then
		node.entry.remove()
		return node.value
	end
	return
end

--[=[
	Pops an entry off of the back of the List.

	@within LinkedList
]=]
function LinkedList:Pop(): unknown
	local node = self.back
	if node then
		node.entry.remove()
		return node.value
	end
	return
end

--[=[
	Iterates over all entries in this List.

	Iteration returns the value stored in each entry, followed by an [Entry]
	object which can be used to manipulate this entry in the List.

	@within LinkedList
]=]
function LinkedList:__iter(): <T>() -> (T, Entry<T>)
	local node: UnknownNode? = self.front

	return function()
		if not node then
			return
		end

		local currentNode = node
		node = node.next
		return currentNode.value, currentNode.entry
	end
end

return LinkedList
