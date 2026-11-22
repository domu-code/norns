-- Norns Pocket 0.4 additional compatibility helpers.
-- Loaded after bootstrap.lua, before the selected user script.
-- No native SuperCollider engines are implied by these adapters.

do
  local function simple_option(id,options)
    local o={id=id,options=options or {},value=1,action=nil}
    function o:set(v)
      self.value=math.floor(util.clamp(v,1,math.max(1,#self.options)))
      if self.action then self.action(self.value) end
    end
    function o:delta(d) self:set(self.value+(d>0 and 1 or -1)) end
    function o:get() return self.value end
    function o:string() return tostring(self.options[self.value] or "") end
    return o
  end
  local function simple_control(id,spec)
    local o={id=id,spec=spec,value=spec.default or spec.minval,action=nil}
    function o:set(v)
      self.value=util.clamp(v,self.spec.minval,self.spec.maxval)
      if self.action then self.action(self.value) end
    end
    function o:delta(d) self:set(self.value+d*(self.spec.step>0 and self.spec.step or .01)) end
    function o:get() return self.value end
    function o:string() return tostring(self.value) end
    return o
  end
  package.preload["params/option"]=function()
    return {new=function(id,opts) return simple_option(id,opts) end}
  end
  package.preload["params/control"]=function()
    return {new=function(id,spec) return simple_control(id,spec) end}
  end

  -- Older norns scripts use add_option(id, options) and add_number(id, min, max, default).
  local add_option=params.add_option
  function params:add_option(id,name,options,default)
    if type(name)=="table" then
      default=options
      options=name
      name=id
    end
    return add_option(self,id,name,options,default)
  end
  local add_number=params.add_number
  function params:add_number(id,name,minimum,maximum,default,formatter)
    if type(name)=="number" then
      formatter=default
      default=maximum
      maximum=minimum
      minimum=name
      name=id
    end
    return add_number(self,id,name,minimum,maximum,default,formatter)
  end
  local add_control=params.add_control
  function params:add_control(id,name,spec,formatter)
    if type(name)=="table" then
      formatter=spec
      spec=name
      name=id
    end
    return add_control(self,id,name,spec,formatter)
  end

  function params:save(name) return self:write(name) end
  function params:load(name) return self:read(name) end
  function params:set_save() end
  function params:set_read() end
  function params:set_write() end
end

metro.alloc=function(fn,time,count)
  return metro.init(fn,time,count)
end

function util.sign(v)
  if v>0 then return 1 elseif v<0 then return -1 else return 0 end
end
function util.linlin(a,b,c,d,x)
  if b==a then return c end
  return c+(d-c)*((x-a)/(b-a))
end
function util.acronym(str)
  local result=""
  for token in tostring(str):gmatch("%S+") do result=result..token:sub(1,1) end
  return result
end

midi.devices=midi.devices or {}
midi.vports=midi.vports or {
  {name="Android MIDI 1",port=1}
}

if _path and _path.data then data_dir=_path.data end
