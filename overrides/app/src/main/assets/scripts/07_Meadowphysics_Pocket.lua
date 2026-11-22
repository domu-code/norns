-- Meadowphysics Pocket: original cascading counter/sequencer interpretation.
-- Inspired by the monome Meadowphysics concept, not the original script source.
-- Physical monome 64: use PAGE A / B to edit all 16 counter positions.
local g=grid.connect(1)
local midiOut=midi.connect(1)
local lengths={3,5,7,9,11,13,15,16}
local counts={0,0,0,0,0,0,0,0}
local notes={36,38,42,46,48,50,55,60}
local bpm=116
local run=true
local selected=1
local cascade=65
local function drawGrid()
  g:all(0)
  for row=1,8 do
    for x=1,16 do
      local l=x<=lengths[row] and 2 or 0
      if x==counts[row]+1 then l=13 end
      if x==lengths[row] then l=9 end
      g:led(x,row,l)
    end
  end
  g:refresh()
end
function redraw()
  screen.clear();screen.level(15)
  screen.move(0,9);screen.text("MEADOWPHYSICS / POCKET")
  screen.level(8);screen.move(0,23);screen.text("BPM "..bpm.." ROW "..selected)
  screen.move(0,36);screen.text("LEN "..lengths[selected].."  CASCADE "..cascade)
  screen.move(0,48);screen.text(run and "COUNTERS RUNNING" or "COUNTERS PAUSED")
  screen.level(3);screen.move(0,62);screen.text("K2 RUN  K3 RESET")
  screen.update()
end
local function fire(row)
  local note=notes[row]
  engine.hz(musicutil.note_num_to_freq(note+12))
  midiOut:note_on(note,100,10)
  clock.run(function()
    clock.sleep(.07);midiOut:note_off(note,0,10)
  end)
end
local function increment(row,depth)
  if row>8 or depth>8 then return end
  counts[row]=counts[row]+1
  if counts[row]>=lengths[row] then
    counts[row]=0;fire(row)
    if math.random(100)<=cascade then increment(row+1,depth+1) end
  end
end
function init()
  clock.set_tempo(bpm);drawGrid();redraw()
  clock.run(function()
    while true do
      clock.sync(.25)
      if run then
        increment(1,1)
        drawGrid();redraw()
      end
    end
  end)
end
g.key=function(x,y,z)
  if z~=1 then return end
  selected=y;lengths[y]=x;counts[y]=counts[y]%lengths[y]
  drawGrid();redraw()
end
function key(n,z)
  if z~=1 then return end
  if n==2 then run=not run end
  if n==3 then for i=1,8 do counts[i]=0 end end
  drawGrid();redraw()
end
function enc(n,d)
  if n==1 then bpm=util.clamp(bpm+d,20,260);clock.set_tempo(bpm)
  elseif n==2 then selected=util.clamp(selected+d,1,8)
  elseif n==3 then cascade=util.clamp(cascade+d*2,0,100) end
  drawGrid();redraw()
end
