--!strict

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type Limiter = typeof(setmetatable({} :: {
	_window: number,
	_max: number,
	_hits: { [number]: { number } },
}, RateLimiter))

function RateLimiter.new(maxPerSecond: number): Limiter
	return setmetatable({
		_window = 1,
		_max = maxPerSecond,
		_hits = {},
	}, RateLimiter)
end

function RateLimiter.allow(self: Limiter, userId: number): boolean
	local now = os.clock()
	local list = self._hits[userId]
	if not list then
		list = {}
		self._hits[userId] = list
	end
	local keep = {}
	for _, t in list do
		if now - t <= self._window then
			table.insert(keep, t)
		end
	end
	self._hits[userId] = keep
	if #keep >= self._max then
		return false
	end
	table.insert(keep, now)
	return true
end

function RateLimiter.clear(self: Limiter, userId: number)
	self._hits[userId] = nil
end

return RateLimiter
