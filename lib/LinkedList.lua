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

local LinkedList = {}
LinkedList.__index = LinkedList

LinkedList.__iter = function(list: typeof(LinkedList.new())): <T>() -> (T, Entry<T>)
	return list:Iterate()
end

function LinkedList.new()
	local self = setmetatable({}, LinkedList)
	return self
end

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

function LinkedList:Shift(): unknown
	local node = self.front
	if node then
		node.entry.remove()
		return node.value
	end
	return
end

function LinkedList:Pop(): unknown
	local node = self.back
	if node then
		node.entry.remove()
		return node.value
	end
	return
end

function LinkedList:Iterate(): <T>() -> (T, Entry<T>)
	local node: UnknownNode? = self.front

	return function()
		while node do
			local currentNode = node
			node = node.next
			return currentNode.value, currentNode.entry
		end

		return
	end
end

return LinkedList
