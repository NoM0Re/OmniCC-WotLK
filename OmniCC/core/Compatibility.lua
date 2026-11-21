do
  local AddonName, Addon = ...
  local floor = math.floor

  local containerStates = setmetatable({}, { __mode = "k" })
  local ContainerMethods = {}
  local ContainerMetatable

  local function GetContainerState(container)
    return containerStates[container]
  end

  local function CreateContainerView(state)
    local container = setmetatable({}, ContainerMetatable)
    containerStates[container] = state
    return container
  end

  ContainerMetatable = {
    __index = function(container, key)
      local method = ContainerMethods[key]
      if method then
        return method
      end
      return GetContainerState(container).fields[key]
    end,
    __newindex = function(container, key, value)
      if ContainerMethods[key] then
        error("Attempted to assign to read-only key '" .. key .. "'", 2)
      end
      GetContainerState(container).fields[key] = value
    end,
    __eq = function(left, right)
      return GetContainerState(left) == GetContainerState(right)
    end,
    __metatable = true,
  }

  local C_FunctionContainers = {}

  function C_FunctionContainers.CreateCallback(callback)
    if type(callback) ~= "function" then
      error(("Bad argument #1 to 'CreateCallback' (function expected, got %s)"):format(callback ~= nil and type(callback) or "no value"), 2)
    end

    return CreateContainerView({
      callback = callback,
      cancelled = false,
      fields = {},
    })
  end

  function ContainerMethods:Cancel()
    GetContainerState(self).cancelled = true
  end

  function ContainerMethods:IsCancelled()
    return GetContainerState(self).cancelled
  end

  function ContainerMethods:Invoke(...)
    local state = GetContainerState(self)
    if not state.cancelled then
      state.callback(...)
    end
  end

  local C_Timer = {}
  local waitTable = {}

  local function ReleaseTicker(ticker)
    ticker.state = nil
    ticker.callbackView = nil
  end

  local total = 0

  local function WaitFunc(self)
    local now = GetTime()
    local i = 1

    while i <= total do
      local ticker = waitTable[i]
      local elapsed = floor((now - ticker.lastUpdate) * 1000 + 0.5) % 2^32

      if ticker.state.cancelled then
        ReleaseTicker(table.remove(waitTable, i))
        total = total - 1
      elseif ticker.delay > elapsed then
        ticker.delay = ticker.delay - elapsed
        ticker.lastUpdate = now
        i = i + 1
      else
        if ticker.iterations ~= 1 then
          ticker.lastUpdate = GetTime()
        end
        local ok, err = pcall(ticker.state.callback, ticker.callbackView)
        if not ok then
          pcall(geterrorhandler(), err)
        end

        if ticker.state.cancelled then
          ReleaseTicker(table.remove(waitTable, i))
          total = total - 1
        elseif ticker.iterations == -1 then
          ticker.delay = ticker.duration
          i = i + 1
        elseif ticker.iterations > 1 then
          ticker.iterations = ticker.iterations - 1
          ticker.delay = ticker.duration
          i = i + 1
        elseif ticker.iterations == 1 then
          ReleaseTicker(table.remove(waitTable, i))
          total = total - 1
        end
      end
    end

    total = #waitTable
    if total == 0 then
      self:Hide()
    end
  end

  local waitFrame = CreateFrame("Frame")
  waitFrame:Hide()
  waitFrame:SetScript("OnUpdate", WaitFunc)

  local function AddDelayedCall(ticker)
    local delay = floor(ticker.delay * 1000)
    if delay * 0.001 < ticker.delay then
      delay = delay + 1
    end
    ticker.delay = delay
    ticker.duration = delay
    ticker.lastUpdate = GetTime()
    table.insert(waitTable, ticker)
    waitFrame:Show()
  end

  local function ValidateArguments(duration, callback, callFunc)
    if type(duration) ~= "number" then
      error(("Bad argument #1 to '%s' (number expected, got %s)"):format(callFunc, duration ~= nil and type(duration) or "no value"), 2)
    elseif type(callback) ~= "function" and not GetContainerState(callback) then
      error(("Bad argument #2 to '%s' (function expected, got %s)"):format(callFunc, callback ~= nil and type(callback) or "no value"), 2)
    end
  end

  local function ValidateIterations(iterations)
    if iterations ~= nil and (type(iterations) ~= "number" or iterations < 1 or iterations ~= floor(iterations)) then
      error(("Bad argument #3 to 'NewTicker' (positive integer expected, got %s)"):format(iterations ~= nil and tostring(iterations) or "no value"), 3)
    end
  end

  function C_Timer.After(duration, callback)
    ValidateArguments(duration, callback, "After")

    local state = GetContainerState(callback) or {
      callback = callback,
      cancelled = false,
      fields = {},
    }
    AddDelayedCall({
      state = state,
      callbackView = CreateContainerView(state),
      iterations = 1,
      delay = math.max(0.01, duration),
    })
  end

  local function CreateTicker(duration, callback, iterations)
    local state = GetContainerState(callback) or {
      callback = callback,
      cancelled = false,
      fields = {},
    }
    local ticker = {
      state = state,
      callbackView = CreateContainerView(state),
      iterations = iterations or -1,
      delay = math.max(0.01, duration),
    }

    AddDelayedCall(ticker)
    return CreateContainerView(state)
  end

  function C_Timer.NewTicker(duration, callback, iterations)
    ValidateArguments(duration, callback, "NewTicker")
    ValidateIterations(iterations)
    return CreateTicker(duration, callback, iterations)
  end

  function C_Timer.NewTimer(duration, callback)
    ValidateArguments(duration, callback, "NewTimer")
    return CreateTicker(duration, callback, 1)
  end

  function C_Timer.CancelTimer(ticker, silent)
    if ticker and ticker.Cancel then
      ticker:Cancel()
    elseif not silent then
      error(AddonName .. ": CancelTimer(timer[, silent]): '" .. tostring(ticker) .. "' - no such timer registered")
    end
    return nil
  end

  local function RunNextFrame(callback)
    C_Timer.After(0, callback)
  end

  local exports = {
    C_FunctionContainers = C_FunctionContainers,
    C_Timer = C_Timer,
    RunNextFrame = RunNextFrame,
  }

  for name, value in pairs(exports) do
    Addon[name] = value
    if _G[name] == nil then
      _G[name] = value
    end
  end
end
