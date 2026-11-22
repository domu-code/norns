-- Bloom Pocket: original generative garden, inspired by schollz/Bloom (MIT).
-- This is a lightweight Android adaptation, not the original norns Bloom script.
-- Touch grid to seed notes; K3 generates a new pattern; K2 clears.
local g=grid.connect(1)
local m=midi.connect(1)
local seeds={}
local blooms={}
local root=48
local spacing=.36
local variation=35
local playing=true
local count=0
local function seed(x,y)
  seeds[#seeds+1]={x=x,y=y}
  if #seeds>32 then table.remove(seeds,1) end
end
local function leds()
  g:all(0)
  for _,p in ipairs(seeds) do g:led(p.x,p.y,9) end
  for _,p in ipairs(blooms) do
    g:led(p.x,p.y,15)
  end
  g:refresh()
end
function redraw()
  screen.clear();screen.level(15)
  screen.move(0,9);screen.text("BLOOM / POCKET EDITION")
  screen.level(6);screen.move(0,22);screen.text("ROOT "..root.."  SEEDS "..#seeds)
  screen.move(0,34);screen.text("SPACE "..string.format("%.2f",spacing))
  screen.move(0,45);screen.text("EVOLVE "..variation.."%")
  for _,b in ipairs(blooms) do
    local radius=b.life*3
    screen.level(math.max(1,math.floor(b.life*12)))
    screen.circle(b.x*7+3,b.y*5+20,radius);screen.stroke()
  end
  screen.level(4);screen.move(0,62);screen.text("K2 CLEAR K3 SCATTER")
  screen.update()
end
local function pulse()
  if #seeds==0 then return end
  local p=seeds[math.random(#seeds)]
  local x,y=p.x,p.y
  if math.random(100)<variation then x=util.clamp(x+math.random(-2,2),1,16) end
  if math.random(100)<variation then y=util.clamp(y+math.random(-1,1),1,8) end
  local note=util.clamp(root+(8-y)*2+((x-1)%5)*3,24,108)
  engine.hz(musicutil.note_num_to_freq(note))
  m:note_on(note,82,1)
  clock.run(function() clock.sleep(.25);m:note_off(note,0,1) end)
  blooms[#blooms+1]={x=x,y=y,life=1}
  count=count+1
end
function init()
  math.randomseed(math.floor(util.time()*1000)%10000000)
  for i=1,7 do seed(math.random(2,15),math.random(1,8)) end
  redraw();leds()
  clock.run(function()
    while true do
      clock.sleep(spacing)
      if playing then pulse() end
      for i=#blooms,1,-1 do
        blooms[i].life=blooms[i].life-.2
        if blooms[i].life<=0 then table.remove(blooms,i) end
      end
      redraw();leds()
    end
  end)
end
g.key=function(x,y,z)
  if z~=1 then return end
  seed(x,y);redraw();leds()
end
function key(n,z)
  if z~=1 then return end
  if n==2 then seeds={};blooms={}
  elseif n==3 then
    seeds={}
    for i=1,math.random(5,14) do seed(math.random(1,16),math.random(1,8)) end
  end
  redraw();leds()
end
function enc(n,d)
  if n==1 then root=util.clamp(root+d,24,84)
  elseif n==2 then spacing=util.clamp(spacing+d*.02,.08,2)
  elseif n==3 then variation=util.clamp(variation+d*2,0,100) end
  redraw()
end
