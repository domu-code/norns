-- Awake Pocket: independently written norns-style evolving melodic sequencer.
-- Inspired by the classic norns Awake workflow, NOT tehn's original Awake code.
-- This uses the Android sine engine and optionally sends USB MIDI.
local g=grid.connect(1)
local out=midi.connect(1)
local pattern={0,2,4,7,9,7,4,2,0,4,7,11,9,7,4,2}
local enabled={}
for i=1,16 do enabled[i]=true end
local scale={0,2,4,5,7,9,11}
local root=48
local bpm=112
local density=85
local step=1
local running=true
local evolve=false
local function light()
  g:all(0)
  for x=1,16 do
    local y=8-math.floor(pattern[x]/2)
    g:led(x,math.max(1,y),enabled[x] and 9 or 2)
    g:led(x,8,x==step and 15 or 3)
  end
  g:refresh()
end
function redraw()
  screen.clear()
  screen.level(15);screen.move(0,9);screen.text("AWAKE / POCKET EDITION")
  screen.level(9);screen.move(0,23);screen.text("BPM "..bpm.."   ROOT "..root)
  screen.move(0,35);screen.text("DENSITY "..density.."%")
  screen.move(0,47);screen.text(running and "PLAY" or "STOP")
  screen.move(45,47);screen.text(evolve and "EVOLVE ON" or "EVOLVE OFF")
  screen.level(4);screen.move(0,62);screen.text("K2 RUN  K3 EVOLVE")
  screen.update()
end
local function noteoff(n)
  clock.run(function()
    clock.sleep(.12)
    out:note_off(n,0,1)
  end)
end
local function trigger()
  if not enabled[step] or math.random(100)>density then return end
  local note=root+pattern[step]
  engine.hz(musicutil.note_num_to_freq(note))
  out:note_on(note,90,1)
  noteoff(note)
end
function init()
  clock.set_tempo(bpm)
  math.randomseed(math.floor(util.time()*1000)%10000000)
  light();redraw()
  clock.run(function()
    while true do
      clock.sync(.5)
      if running then
        trigger()
        if evolve and math.random(100)<12 then
          local x=math.random(1,16)
          pattern[x]=util.clamp(pattern[x]+(math.random(0,1)==0 and -1 or 1),0,14)
        end
        step=step%16+1
        light();redraw()
      end
    end
  end)
end
g.key=function(x,y,z)
  if z~=1 then return end
  if y==8 then enabled[x]=not enabled[x]
  else pattern[x]=util.clamp((8-y)*2,0,14);enabled[x]=true end
  light();redraw()
end
function key(n,z)
  if z~=1 then return end
  if n==2 then running=not running end
  if n==3 then evolve=not evolve end
  redraw();light()
end
function enc(n,d)
  if n==1 then bpm=util.clamp(bpm+d,30,240);clock.set_tempo(bpm)
  elseif n==2 then root=util.clamp(root+d,24,84)
  elseif n==3 then density=util.clamp(density+d*2,0,100) end
  redraw()
end
