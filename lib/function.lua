local fn = {}

function fn.noop() end

function fn.param_value(x) 
  return x:get()
end

function fn.make_q()
  local items = {}
  local q = {}

  function q.nq(item) -- enqueue
    items[#items + 1] = item
  end

  function q.dq() -- dequeue
    return table.remove(items, #items)
  end

  function q.fire(...)
    while #items > 0 do
      q.dq()(...)
    end
  end

  return q
end

-- including name turns debugging on
function fn.make_pub(name)
  local p = {
    subs = {}
  }

  function p.sub(fn)
    if name then print('new subscription to '..name) end
    p.subs[#p.subs+1] = fn
    local id = #p.subs 
    return id
  end

  function p.unsub(id)
    if name then print('unsubscribing id '..id..' from '..name) end
    if id > #p.subs then 
      return false 
    end

    p.subs[id] = fn.noop
    return true
  end

  function p.pub(...)
    --if name then print('publishing '..name) end
    for i = 1, #p.subs do
      p.subs[i](...)
    end
  end

  function p.clear()
    if name then print('clearing subscribers for '..name) end
    p.subs = {}
  end
  
  if name then print('created publisher '..name) end

  return p
end

return fn
